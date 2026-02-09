# SigilML Interpreter Implementation Plan

> **Version**: 2.0
> **Last Updated**: 2026-01-25
> **Status**: Clarified and ready for implementation

## Overview

This document specifies the implementation plan for `sigilml`, a C-based interpreter exposed as both a Python module and a shared library (`libsigilml.so`). The interpreter parses `.sml` files, expands citations according to configurable modes, prevents navigation loops via circuit breaker logic, tracks pathways for reuse, and maintains heatmap data embedded within source documents.

## Clarified Requirements

| Aspect | Decision |
|--------|----------|
| Citation syntax | Closing tag: `\citation[...]{...}\citation` |
| Passage bounds | Line numbers (e.g., `passage="10-25"`) |
| Volume scope | Referential network across distributed HTTPS nodes |
| Remote addressing | Standard HTTPS URLs |
| Authentication | Bearer token from `SIGILML_TOKEN` environment variable |
| Heatmap storage | **Embedded in .sml files** |
| Heatmap writes | Auto-update local; webhook POST for remote |
| Pathway storage | JSON in project-local `.sigilml/pathways/` |
| Output mode | **Streaming, per-citation granularity** |
| Provenance | Optional flag (`--provenance`) |
| Circuit breaker | Config defaults in `.sigilml/config.json`, overridable per-invocation |
| Syllogistic logic | Structural matching on pathway shape |
| PageRank | External file (`.sigilml/pagerank.json`) |
| Input conversion | Generic mapping for JSON/XML to AST |
| Error handling | **Embedded markers**, continue processing |
| Python version | **3.10+** |
| C API | **Shared library** (`libsigilml.so`) with stable ABI |
| API integration | Deferred until core works |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Python Interface                               │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────────────┐ │
│  │ __init__.py  │  │ __main__.py  │  │   Type Stubs (_sigilml.pyi)    │ │
│  └──────┬───────┘  └──────┬───────┘  └────────────────────────────────┘ │
│         └────────┬────────┘                                              │
│                  ▼                                                       │
│         ┌───────────────┐                                                │
│         │  bindings.c   │  ← Python C API                                │
│         └───────┬───────┘                                                │
└─────────────────┼───────────────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    libsigilml.so (Stable C ABI)                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                         sigilml.h (Public API)                      │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                        interpreter.c                                │ │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌───────────────────────┐  │ │
│  │  │ Lexer   │─▶│ Parser  │─▶│Expander │─▶│ Streaming Formatter   │  │ │
│  │  └─────────┘  └─────────┘  └─────────┘  └───────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────────────┐ │
│  │ circuit.c    │  │ pathway.c    │  │         heatmap.c              │ │
│  │ Loop prevent │  │ Thread track │  │ Parse/update embedded blocks   │ │
│  └──────────────┘  └──────────────┘  └────────────────────────────────┘ │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────────┐│
│  │                          fetch.c                                     ││
│  │  HTTP via libcurl | Bearer auth | Webhook POST for remote heatmaps   ││
│  └──────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Lexer and Parser

### 1.1 Token Definitions

| Token              | Pattern                                | Example                                    |
|--------------------|----------------------------------------|--------------------------------------------|
| `ENV_BEGIN`        | `\begin{<name>}`                       | `\begin{project}`                          |
| `ENV_END`          | `\end{<name>}`                         | `\end{project}`                            |
| `COMMAND`          | `\<name>`                              | `\description`, `\goal`                    |
| `ATTR_LIST`        | `[key=val, ...]`                       | `[name=SigilML, status=planned]`           |
| `BRACE_CONTENT`    | `{...}`                                | `{Thin C-based interpreter...}`            |
| `CITATION`         | `\citation[...]{...}\citation`         | Closing tag required                       |
| `SIGIL`            | `\sigil[...]{...}\sigil`               | Closing tag required                       |
| `HEATMAP_BEGIN`    | `\begin{heatmap}`                      | Embedded heatmap block                     |
| `HEATMAP_END`      | `\end{heatmap}`                        | End of heatmap block                       |
| `COMMENT`          | `% ...`                                | `% This is a comment`                      |
| `TEXT`             | Anything else                          | Free-form text between commands            |

### 1.2 AST Node Types

```c
typedef enum {
    NODE_DOCUMENT,      // Root node
    NODE_ENVIRONMENT,   // \begin{...} ... \end{...}
    NODE_COMMAND,       // \command[attrs]{content}
    NODE_CITATION,      // \citation[...]{...}\citation
    NODE_SIGIL,         // \sigil[...]{...}\sigil
    NODE_HEATMAP,       // \begin{heatmap} ... \end{heatmap}
    NODE_TEXT,          // Verbatim text
    NODE_COMMENT,       // % comment (preserved for round-trip)
    NODE_ERROR          // Error marker (embedded error handling)
} NodeType;

typedef struct ASTNode {
    NodeType type;
    char *name;                 // Environment or command name
    AttrList *attrs;            // [key=value, ...] attributes
    char *content;              // Brace content or text
    struct ASTNode *children;   // Child nodes (linked list)
    struct ASTNode *next;       // Sibling nodes
    SourceLoc loc;              // Line/column for error reporting
    char *source_file;          // Provenance: originating file (if enabled)
    int source_line;            // Provenance: originating line (if enabled)
} ASTNode;
```

### 1.3 Parser Implementation

1. **Recursive descent parser** for nested environments
2. **Error recovery**: On malformed input, insert `NODE_ERROR` with message and continue
3. **Streaming mode**: Support parsing from file handle or string buffer
4. **Memory management**: Arena allocator for AST nodes; single `sml_free_document()` releases all
5. **Provenance tracking**: When enabled, annotate each node with source file and line

### 1.4 Files

| File              | Purpose                                          |
|-------------------|--------------------------------------------------|
| `lexer.c`         | Tokeniser with lookahead                         |
| `lexer.h`         | Token type definitions                           |
| `parser.c`        | Recursive descent parser                         |
| `parser.h`        | AST node definitions and API                     |
| `arena.c`         | Arena allocator                                  |
| `arena.h`         | Arena allocator API                              |

---

## Phase 2: Expansion Engine

### 2.1 Expansion Modes

| Mode        | Behaviour                                                              |
|-------------|------------------------------------------------------------------------|
| `DISCARD`   | Remove citation/sigil markers; retain hyperlink text only              |
| `PASSAGE`   | Replace citation with specified lines (e.g., `passage="10-25"`)        |
| `DEFAULT`   | Replace citation with entire referenced document (recursive)           |

### 2.2 Passage Extraction

Passage bounds are specified as **line numbers**:

```
\citation[target="doc.sml", passage="10-25"]{summary text}\citation
```

- `passage="N"` — Single line N
- `passage="N-M"` — Lines N through M inclusive
- `passage="N-"` — Line N to end of document
- `passage="-M"` — Start of document to line M

### 2.3 Mode Selection

```c
typedef enum {
    EXPAND_DISCARD,
    EXPAND_PASSAGE,
    EXPAND_DEFAULT
} ExpansionMode;

typedef struct {
    ExpansionMode mode;
    int max_depth;          // -1 for unlimited
    int max_visits;         // Circuit breaker: max visits per doc (default: 3)
    bool override_embedded; // True: interpreter mode overrides .sml hints
    bool provenance;        // Track source file/line for each node
} ExpandConfig;
```

### 2.4 Citation Resolution

1. Parse citation attributes: `target`, `passage`
2. Determine if target is local path or HTTPS URL
3. If URL → invoke `fetch.c` with bearer auth
4. If local → read file directly
5. Extract passage by line numbers if specified
6. Return resolved content or hyperlink text based on mode

### 2.5 Files

| File              | Purpose                                          |
|-------------------|--------------------------------------------------|
| `expander.c`      | Citation/sigil expansion logic                   |
| `expander.h`      | Expansion mode API                               |
| `resolver.c`      | Target resolution (file, URL, line extraction)   |

---

## Phase 3: Circuit Breaker

### 3.1 Configuration

Defaults stored in `.sigilml/config.json`, overridable per-invocation:

```json
{
  "circuit_breaker": {
    "max_visits": 3,
    "max_depth": 100
  }
}
```

### 3.2 Loop Prevention

```c
typedef struct VisitEntry {
    char *document_id;      // Canonical path or URL
    int visit_count;
    struct VisitEntry *next;
} VisitEntry;

typedef struct {
    VisitEntry *visited;    // Hash table of visited documents
    int max_visits;         // From config or per-invocation
    int max_depth;          // From config or per-invocation
    int current_depth;
} CircuitBreaker;
```

### 3.3 Behaviour

1. Before loading any document, check `visited` table
2. If `visit_count >= max_visits` → insert `NODE_ERROR` marker, skip document
3. If `current_depth >= max_depth` → insert `NODE_ERROR` marker, return partial
4. On successful load → increment `visit_count`, push depth

### 3.4 Files

| File              | Purpose                                          |
|-------------------|--------------------------------------------------|
| `circuit.c`       | Circuit breaker state and checks                 |
| `circuit.h`       | API for visit tracking                           |

---

## Phase 4: Output Formatter (Streaming)

### 4.1 Output Formats

| Format      | Description                                                        |
|-------------|--------------------------------------------------------------------|
| `SML`       | Round-trip preserving; can be fed back into interpreter            |
| `XML`       | Structure-preserving; citations become `<citation>` elements       |
| `PLAINTEXT` | All markup stripped; suitable for embedding in non-rich contexts   |

### 4.2 Streaming Interface

Output is yielded **per-citation** as citations are resolved:

```c
typedef enum {
    FORMAT_SML,
    FORMAT_XML,
    FORMAT_PLAINTEXT
} OutputFormat;

// Callback invoked for each formatted chunk
typedef void (*OutputCallback)(const char *chunk, size_t len, void *userdata);

// Streaming formatter
void sml_format_stream(
    ASTNode *root,
    OutputFormat fmt,
    OutputCallback callback,
    void *userdata
);

// Batch formatter (convenience wrapper)
char *sml_format_document(ASTNode *root, OutputFormat fmt);
```

### 4.3 Files

| File              | Purpose                                          |
|-------------------|--------------------------------------------------|
| `formatter.c`     | AST → string conversion with streaming support   |
| `formatter.h`     | Output format API                                |

---

## Phase 5: Pathway Tracking

### 5.1 Pathway Data Structure

```c
typedef struct PathwayStep {
    char *document_id;
    ExpansionMode mode_used;
    char *passage_spec;         // e.g., "10-25" or NULL for full doc
    double relevance_score;
    time_t timestamp;
    struct PathwayStep *next;
} PathwayStep;

typedef struct {
    char *pathway_id;           // UUID
    PathwayStep *steps;
    int step_count;
    double average_relevance;
    int reuse_count;
    time_t created;
    time_t last_used;
} Pathway;
```

### 5.2 Operations

| Operation              | Description                                                  |
|------------------------|--------------------------------------------------------------|
| `pathway_start()`      | Begin recording a new pathway                                |
| `pathway_step()`       | Record a navigation step                                     |
| `pathway_end()`        | Finalise and store pathway                                   |
| `pathway_find()`       | Search for existing pathways matching a pattern              |
| `pathway_replay()`     | Load multiple documents in single operation                  |
| `pathway_transform()`  | Structural matching: substitute nodes with same edge types   |

### 5.3 Syllogistic Transformation

Structural matching replaces nodes while preserving pathway shape:

```
Original: Paris → France → Europe
Pattern:  capital_of → country → continent

Transform with (Rome):
Result:   Rome → Italy → Europe
```

The transformation validates that edges of the same type exist in the knowledge graph before substitution.

### 5.4 Storage

- **In-memory**: Hash table during session
- **Persistent**: JSON files in `.sigilml/pathways/`
- **Pruning**: Pathways below relevance threshold removed on session end

### 5.5 Files

| File              | Purpose                                          |
|-------------------|--------------------------------------------------|
| `pathway.c`       | Pathway recording and retrieval                  |
| `pathway.h`       | Pathway data structures and API                  |
| `pathway_store.c` | Persistent storage (JSON read/write)             |
| `pathway_transform.c` | Syllogistic structural matching              |

---

## Phase 6: Heatmap Generation

### 6.1 Embedded Storage

Heatmap data is **embedded within .sml files** as a special environment:

```latex
\begin{heatmap}
  \entry[source="doc1.sml", target="doc2.sml", correlation=0.85, trend=0.1, access_count=12, last_access=1706140800]
  \entry[source="doc1.sml", target="doc3.sml", correlation=0.42, trend=-0.2, access_count=3, last_access=1705968000]
\end{heatmap}
```

### 6.2 Heatmap Entry

```c
typedef struct HeatmapEntry {
    char *source_doc;       // Document containing the citation
    char *target_doc;       // Cited document
    double correlation;     // 0.0–1.0: probability of following link
    double trend;           // -1.0 to 1.0: usage trajectory
    time_t last_access;
    int access_count;
    bool immortal;          // Prevents pruning
    struct HeatmapEntry *next;
} HeatmapEntry;
```

### 6.3 Time Decay Formula

```
effective_score = correlation * exp(-λ * (now - last_access))

where λ = decay constant (default: 0.01 per day)
```

### 6.4 Auto-Update Behaviour

| File Type | Behaviour |
|-----------|-----------|
| Local file | Write updated heatmap block back to .sml file |
| Remote URL | POST heatmap delta to configured webhook |

Webhook configuration in `.sigilml/config.json`:

```json
{
  "heatmap_webhook": "https://example.com/api/heatmap"
}
```

Webhook payload:

```json
{
  "document_url": "https://example.com/doc.sml",
  "entries": [
    {"source": "doc1.sml", "target": "doc2.sml", "correlation": 0.85, "trend": 0.1}
  ]
}
```

### 6.5 Pruning Rules

1. `correlation < 0.3` AND `days_since_access > 30` → **prune**
2. `access_count == 0` AND `days_since_creation > 7` → **prune**
3. `immortal == true` → **never prune**

### 6.6 PageRank Integration

- External PageRank scores loaded from `.sigilml/pagerank.json`
- Combined score: `final = α * heatmap_score + (1-α) * pagerank_score`
- Default α = 0.7 (prefer heatmap data)

### 6.7 Files

| File              | Purpose                                          |
|-------------------|--------------------------------------------------|
| `heatmap.c`       | Heatmap tracking and scoring                     |
| `heatmap.h`       | Heatmap data structures and API                  |
| `heatmap_embed.c` | Parse/write embedded heatmap blocks              |
| `pagerank.c`      | PageRank loader and score combiner               |

---

## Phase 7: HTTP Fetching

### 7.1 Fetch Behaviour

- **No caching**: Every request fetches fresh data
- **Timeout**: Default 30 seconds
- **User-Agent**: `SigilML/<version>`
- **Authentication**: Bearer token from `SIGILML_TOKEN` environment variable
- **Content-Type handling**: Parse JSON, XML, or treat as plaintext

### 7.2 Interface

```c
typedef struct {
    char *content;
    size_t length;
    int status_code;
    char *content_type;
    char *error;            // NULL if success
} FetchResult;

// Fetch with bearer auth from SIGILML_TOKEN env var
FetchResult sml_fetch_url(const char *url, int timeout_ms);

// POST heatmap delta to webhook
int sml_post_heatmap(const char *webhook_url, const char *json_payload);

void sml_fetch_result_free(FetchResult *result);
```

### 7.3 Files

| File              | Purpose                                          |
|-------------------|--------------------------------------------------|
| `fetch.c`         | libcurl wrapper with auth                        |
| `fetch.h`         | Fetch API                                        |

---

## Phase 8: Python Bindings

### 8.1 Module Structure

```
sigilml/
├── __init__.py      # Python interface, type hints
├── __main__.py      # CLI entry point
├── _sigilml.so      # Compiled C extension (links libsigilml.so)
├── _sigilml.pyi     # Type stubs for IDE support
└── py.typed         # PEP 561 marker
```

### 8.2 Python API

```python
# sigilml/__init__.py

from enum import Enum
from typing import Iterator, Optional, Dict, Any
from collections.abc import Callable

class ExpansionMode(Enum):
    DISCARD = 0
    PASSAGE = 1
    DEFAULT = 2

class OutputFormat(Enum):
    SML = 0
    XML = 1
    PLAINTEXT = 2

class InputFormat(Enum):
    SML = 0
    JSON = 1
    XML = 2

def parse(
    source: str | bytes,
    *,
    input_format: InputFormat = InputFormat.SML,
    expansion_mode: ExpansionMode = ExpansionMode.DEFAULT,
    output_format: OutputFormat = OutputFormat.SML,
    max_depth: int = -1,
    max_visits: int = 3,
    override: bool = False,
    provenance: bool = False
) -> str:
    """Parse and expand an SML document (batch mode)."""
    ...

def parse_stream(
    source: str | bytes,
    *,
    input_format: InputFormat = InputFormat.SML,
    expansion_mode: ExpansionMode = ExpansionMode.DEFAULT,
    output_format: OutputFormat = OutputFormat.SML,
    max_depth: int = -1,
    max_visits: int = 3,
    override: bool = False,
    provenance: bool = False
) -> Iterator[str]:
    """Parse and expand, yielding chunks per-citation."""
    ...

def parse_file(
    path: str,
    *,
    expansion_mode: ExpansionMode = ExpansionMode.DEFAULT,
    output_format: OutputFormat = OutputFormat.SML,
    max_depth: int = -1,
    max_visits: int = 3,
    override: bool = False,
    provenance: bool = False
) -> str:
    """Parse and expand an SML file (batch mode)."""
    ...

def parse_file_stream(
    path: str,
    *,
    expansion_mode: ExpansionMode = ExpansionMode.DEFAULT,
    output_format: OutputFormat = OutputFormat.SML,
    max_depth: int = -1,
    max_visits: int = 3,
    override: bool = False,
    provenance: bool = False
) -> Iterator[str]:
    """Parse and expand an SML file, yielding chunks per-citation."""
    ...

def get_pathway() -> Dict[str, Any]:
    """Retrieve the pathway from the most recent parse operation."""
    ...

def get_heatmap() -> Dict[str, Dict[str, float]]:
    """Retrieve the current heatmap data."""
    ...

def replay_pathway(pathway_id: str) -> str:
    """Replay a stored pathway, loading all documents in one step."""
    ...

def transform_pathway(pathway_id: str, start_node: str) -> str:
    """Apply syllogistic transformation to a pathway."""
    ...
```

### 8.3 CLI Interface

```bash
# Via python -m
python -m sigilml input.sml --mode passage --format xml

# Arguments
#   positional: input file or - for stdin
#   --mode: discard | passage | default
#   --format: sml | xml | plaintext
#   --input-format: sml | json | xml
#   --max-depth: integer, -1 for unlimited
#   --max-visits: integer, circuit breaker limit
#   --override: use interpreter mode over embedded hints
#   --provenance: annotate output with source file/line
#   --stream: output per-citation instead of batch
#   --pathway: show pathway after output
#   --heatmap: show heatmap after output
```

### 8.4 Files

| File              | Purpose                                          |
|-------------------|--------------------------------------------------|
| `bindings.c`      | Python C API module definition                   |
| `__init__.py`     | Python wrapper and type definitions              |
| `__main__.py`     | CLI entry point                                  |
| `_sigilml.pyi`    | Type stubs for IDE support                       |

---

## Phase 9: Build System

### 9.1 Structure

```
SigilML/
├── src/
│   └── sigilml/
│       ├── sigilml.h         # Public C API header
│       ├── lexer.c / .h
│       ├── parser.c / .h
│       ├── arena.c / .h
│       ├── expander.c / .h
│       ├── resolver.c
│       ├── circuit.c / .h
│       ├── formatter.c / .h
│       ├── pathway.c / .h
│       ├── pathway_store.c
│       ├── pathway_transform.c
│       ├── heatmap.c / .h
│       ├── heatmap_embed.c
│       ├── pagerank.c
│       ├── fetch.c / .h
│       ├── bindings.c
│       ├── __init__.py
│       ├── __main__.py
│       ├── _sigilml.pyi
│       └── py.typed
├── include/
│   └── sigilml.h             # Installed public header
├── tests/
│   ├── test_lexer.py
│   ├── test_parser.py
│   ├── test_expander.py
│   ├── test_circuit.py
│   ├── test_pathway.py
│   ├── test_heatmap.py
│   ├── test_formatter.py
│   ├── test_streaming.py
│   └── test_cli.py
├── .sigilml/                 # Project-local cache (created at runtime)
│   ├── config.json
│   ├── pathways/
│   └── pagerank.json
├── pyproject.toml
├── setup.py
├── Makefile
└── CLAUDE.md
```

### 9.2 pyproject.toml

```toml
[build-system]
requires = ["setuptools>=61", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "sigilml"
version = "0.1.0"
description = "SML file interpreter with citation expansion and navigation tracking"
requires-python = ">=3.10"
dependencies = []

[project.optional-dependencies]
dev = ["pytest", "pytest-cov", "mypy", "ruff"]

[project.scripts]
sigilml = "sigilml.__main__:main"
```

### 9.3 Makefile

```makefile
CC = gcc
CFLAGS = -O2 -fPIC -Wall -Wextra -std=c11
LDFLAGS = -lcurl

# Shared library
LIB_SOURCES = $(filter-out src/sigilml/bindings.c, $(wildcard src/sigilml/*.c))
LIB_OBJECTS = $(LIB_SOURCES:.c=.o)

libsigilml.so: $(LIB_OBJECTS)
	$(CC) -shared -o $@ $^ $(LDFLAGS)

# Python extension
PY_CFLAGS = $(CFLAGS) $(shell python3-config --includes)
PY_LDFLAGS = $(shell python3-config --ldflags) -L. -lsigilml

src/sigilml/_sigilml.so: src/sigilml/bindings.o libsigilml.so
	$(CC) -shared -o $@ src/sigilml/bindings.o $(PY_LDFLAGS)

src/sigilml/bindings.o: src/sigilml/bindings.c
	$(CC) $(PY_CFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

install-lib: libsigilml.so
	install -d /usr/local/lib
	install -m 644 libsigilml.so /usr/local/lib/
	install -d /usr/local/include
	install -m 644 include/sigilml.h /usr/local/include/
	ldconfig

clean:
	rm -f src/sigilml/*.o libsigilml.so src/sigilml/_sigilml.so

.PHONY: install-lib clean
```

---

## Phase 10: Testing Strategy

### 10.1 Unit Tests

| Test File              | Coverage                                      |
|------------------------|-----------------------------------------------|
| `test_lexer.py`        | Token recognition, edge cases, malformed input|
| `test_parser.py`       | AST construction, nested environments         |
| `test_expander.py`     | All three expansion modes, line extraction    |
| `test_circuit.py`      | Loop detection, depth limits, config override |
| `test_pathway.py`      | Recording, replay, syllogistic transformation |
| `test_heatmap.py`      | Scoring, decay, embedded parsing, webhook     |
| `test_formatter.py`    | SML, XML, plaintext output                    |
| `test_streaming.py`    | Per-citation streaming output                 |

### 10.2 Integration Tests

| Test File              | Coverage                                      |
|------------------------|-----------------------------------------------|
| `test_cli.py`          | Full CLI invocation with all flags            |
| `test_recursive.py`    | Multi-document traversal                      |
| `test_remote.py`       | HTTPS fetching with mock server               |
| `test_provenance.py`   | Source tracking through expansion             |

### 10.3 Fixtures

```
tests/fixtures/
├── simple.sml           # Basic document
├── nested.sml           # Nested environments
├── citations.sml        # Various citation formats
├── passages.sml         # Line-based passage extraction
├── loop.sml             # Circular reference
├── heatmap.sml          # Embedded heatmap block
└── remote/              # Mock remote documents
```

---

## Implementation Order

| Phase | Milestone                     | Depends On | Notes |
|-------|-------------------------------|------------|-------|
| 1     | Lexer and Parser              | —          | Include heatmap block parsing |
| 2     | Expansion Engine              | Phase 1    | Line-based passage extraction |
| 3     | Circuit Breaker               | Phase 2    | Configurable limits |
| 4     | Output Formatter              | Phase 1    | Streaming per-citation |
| 5     | Pathway Tracking              | Phase 2, 3 | Structural transformation |
| 6     | Heatmap Generation            | Phase 1    | Embedded storage, webhook |
| 7     | HTTP Fetching                 | Phase 2    | Bearer auth, webhook POST |
| 8     | Python Bindings               | All above  | Iterator-based streaming |
| 9     | Build System                  | Phase 8    | Shared library + Python ext |
| 10    | Testing                       | All above  | Ongoing |

---

## Critical Design Decisions

### D1: Memory Management

**Decision**: Arena allocator for AST; explicit free for session data.

**Rationale**: SML documents can be deeply nested. Arena allocation simplifies cleanup and prevents leaks from complex ownership graphs.

### D2: Thread Safety

**Decision**: Not thread-safe by default; per-interpreter state.

**Rationale**: Typical usage is single-threaded (CLI or agent loop). Thread safety adds complexity without benefit for primary use case. Users requiring concurrency should instantiate separate interpreters.

### D3: Citation Format

**Decision**: LaTeX-style `\citation[attrs]{text}\citation` with closing tag.

**Rationale**:
- Closing tag enables unambiguous parsing without lookahead
- Consistent with environment syntax
- Distinct from standard LaTeX `\cite{}` to avoid collision

### D4: No Caching

**Decision**: HTTP responses never cached; always fetch fresh.

**Rationale**: SigilML is designed for live data integration. Caching would introduce staleness.

### D5: Embedded Heatmap

**Decision**: Heatmap data stored as `\begin{heatmap}` blocks within .sml files.

**Rationale**:
- Keeps relevance data co-located with content
- Single file contains all necessary context
- Remote documents can have their own heatmaps

### D6: Streaming Output

**Decision**: Per-citation granularity for streaming.

**Rationale**: Allows consumers to process results incrementally during long traversals without waiting for full expansion.

### D7: Shared Library

**Decision**: Build `libsigilml.so` with stable C ABI.

**Rationale**: Enables FFI from Elixir, Rust, and other languages without going through Python.

---

## Error Handling

All errors are **embedded as markers** in the output stream, allowing processing to continue:

| Error Type              | Marker Format                                    |
|-------------------------|--------------------------------------------------|
| Malformed SML           | `\error[type="parse", line=N]{message}\error`    |
| Missing referenced file | `\error[type="resolve", target="..."]{...}\error`|
| HTTP fetch failure      | `\error[type="fetch", url="...", code=N]{...}\error` |
| Circuit breaker trip    | `\error[type="circuit", doc="..."]{...}\error`   |

In plaintext output, errors render as `[ERROR: message]`.

---

## Future Extensions

1. **MCP Integration** (Phase 11): Adapter for Model Context Protocol
2. **Elixir Bindings** (Phase 12): NIF-based interface via libsigilml.so
3. **Rust Bindings** (Phase 13): FFI wrapper with safe API
4. **Visual Pathway Editor** (Phase 14): Interactive graph visualisation
5. **API Integration** (Phase 15): Database, web search, AI model calls

---

## References

- `navigation-system.md` — Detailed navigation behaviour specification
- `process-flow.md` — Mermaid diagrams for all system flows
- `roadmap.json` — Milestone task dependencies
- `notes` — Project knowledge base
