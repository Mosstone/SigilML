# SigilML Process Flow Diagram

## High-Level System Flow

```mermaid
graph TD
    A[Start: User/Model Query] --> B[Sigil.py Interpreter]
    B --> C[Load SML Data]
    C --> D[Parse Citation Network]
    D --> E[Apply Expansion Mode]
    E --> F[Circuit Breaker Check]
    F -->|No Loop| G[Transform Data]
    F -->|Loop Detected| H[Terminate Pathway]
    G --> I[Update Heatmap]
    I --> J[Store/Reuse Pathway]
    J --> K[Return Results]
    K --> L[End: Context Available]
```

## Detailed Process Flow

### 1. Initialization Phase

```mermaid
graph TD
    A1[Receive Query] --> B1[Check Data Format]
    B1 -->|SML| C1[Load SML File]
    B1 -->|JSON| D1[Convert to SML]
    B1 -->|XML| E1[Enrich with Links]
    C1 --> F1[Parse Citations]
    D1 --> F1
    E1 --> F1
    F1 --> G1[Build Knowledge Graph]
```

### 2. Navigation Phase

```mermaid
graph TD
    A2[Start Navigation] --> B2[Select Expansion Mode]
    B2 -->|Discard| C2[Remove Citations]
    B2 -->|Passage| D2[Expand Specific Sections]
    B2 -->|Default| E2[Load Full Document]
    C2 --> F2[Return Clean Text]
    D2 --> F2
    E2 --> F2
    F2 --> G2[Check Circuit Breaker]
    G2 -->|Safe| H2[Continue Navigation]
    G2 -->|Loop| I2[Terminate & Log]
```

### 3. Pathway Management

```mermaid
graph TD
    A3[Navigation Complete] --> B3[Update Heatmap]
    B3 --> C3[Increment Access Count]
    C3 --> D3[Calculate Correlation Scores]
    D3 --> E3[Apply Time Decay]
    E3 --> F3[Prune Low-Score Entries]
    F3 --> G3[Store Pathway]
    G3 --> H3[Check for Reusable Threads]
    H3 -->|Found| I3[Reuse Existing Pathway]
    H3 -->|New| J3[Create New Pathway]
```

### 4. Model Interaction Flow

```mermaid
graph TD
    A4[Model Receives Query] --> B4[Check Context]
    B4 -->|Has Context| C4[Generate Response]
    B4 -->|Needs Data| D4[Call Sigil.py]
    D4 --> E4[Receive SML Data]
    E4 --> F4[Analyze Citations]
    F4 --> G4[Follow Relevant Links]
    G4 --> H4[Build Knowledge Structure]
    H4 --> I4[Update Internal Context]
    I4 --> J4[Generate Informed Response]
```

### 5. Complete Paris Example Flow

```mermaid
graph TD
    A5[User: "Tell me about Paris"] --> B5[Sigil: Load Paris.sml]
    B5 --> C5[Model: Analyze Citations]
    C5 -->|France.sml| D5[Sigil: Load France.sml]
    C5 -->|Eiffel Tower.sml| E5[Sigil: Load Eiffel Tower.sml]
    D5 --> F5[Model: Detect French Revolution relevance]
    F5 --> G5[Sigil: Load French Revolution.sml]
    E5 --> H5[Model: Follow architect citation]
    H5 --> I5[Sigil: Load Gustave Eiffel.sml]
    G5 --> J5[Model: Create Cultural Pathway]
    I5 --> J5
    J5 --> K5[Sigil: Update Heatmap]
    K5 --> L5[Model: Generate Comprehensive Response]
```

### 6. Thread Transformation Example

```mermaid
graph TD
    A6[Original Pathway: Paris.sml → France.sml → French_Culture.sml]
    A6 --> B6[Model: Detect Analogy Pattern]
    B6 --> C6[Transform: Paris → Rome]
    C6 --> D6[New Pathway: Rome.sml → Italy.sml → Italian_Culture.sml]
    D6 --> E6[Sigil: Validate Pathway]
    E6 -->|Valid| F6[Model: Follow Transformed Path]
    E6 -->|Invalid| G6[Model: Find Alternative Path]
```

### 7. Heatmap Data Flow

```mermaid
graph TD
    A7[Citation Accessed] --> B7[Create/Update Heatmap Entry]
    B7 --> C7[Calculate Correlation Score]
    C7 --> D7[Track Usage Trends]
    D7 --> E7[Apply Time Decay Formula]
    E7 --> F7[Compare to Threshold]
    F7 -->|Above| G7[Retain Entry]
    F7 -->|Below| H7[Prune Entry]
    G7 --> I7[Update Knowledge Graph]
    H7 --> I7
```

### 8. Circuit Breaker Logic

```mermaid
graph TD
    A8[Navigation Request] --> B8[Check Visited Documents]
    B8 -->|New| C8[Add to Visited List]
    B8 -->|Seen| D8[Increment Visit Count]
    D8 --> E8[Check Visit Threshold]
    E8 -->|Below| F8[Continue Navigation]
    E8 -->|Above| G8[Log Loop Detected]
    G8 --> H8[Terminate Current Path]
    H8 --> I8[Return Partial Results]
```

## Sequence Diagrams

### Model-Sigil Interaction

```mermaid
sequenceDiagram
    participant User
    participant Model
    participant Sigil
    participant SMLFiles

    User->>Model: "Tell me about Paris"
    Model->>Sigil: request_context("Paris")
    Sigil->>SMLFiles: load("Paris.sml")
    SMLFiles-->>Sigil: Paris.sml content
    Sigil->>Sigil: parse_citations()
    Sigil->>SMLFiles: load("France.sml")
    SMLFiles-->>Sigil: France.sml content
    Sigil->>Sigil: update_heatmap()
    Sigil->>Sigil: store_pathway()
    Sigil-->>Model: context_data
    Model->>Model: analyze_context()
    Model-->>User: "Paris is the capital of France..."
```

### Pathway Reuse Sequence

```mermaid
sequenceDiagram
    participant Model
    participant Sigil
    participant PathwayDB

    Model->>Sigil: find_related_pathways("culture")
    Sigil->>PathwayDB: query_pathways("culture")
    PathwayDB-->>Sigil: [cultural_path, historical_path]
    Sigil->>Sigil: calculate_relevance()
    Sigil->>Sigil: apply_time_decay()
    Sigil-->>Model: relevant_pathways
    Model->>Sigil: use_pathway("cultural_path")
    Sigil->>PathwayDB: increment_usage("cultural_path")
    Sigil->>Sigil: load_pathway_documents()
    Sigil-->>Model: pathway_context
```

## State Transition Diagrams

### Document Processing States

```mermaid
stateDiagram-v2
    [*] --> Loading
    Loading --> Parsing
    Parsing --> Expanding
    Expanding --> Validating
    Validating --> Returning
    Returning --> [*]
    
    Validating --> Error: Loop Detected
    Error --> [*]
```

### Pathway Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Created
    Created --> Active: First Use
    Active --> Active: Subsequent Uses
    Active --> Archived: Low Usage
    Archived --> Active: Reactivated
    Active --> Pruned: Below Threshold
    Pruned --> [*]
```

## Data Flow Diagrams

### Main Processing Pipeline

```mermaid
graph LR
    A[Input Query] --> B[Format Detection]
    B --> C[Data Loading]
    C --> D[Citation Parsing]
    D --> E[Graph Construction]
    E --> F[Pathway Analysis]
    F --> G[Heatmap Update]
    G --> H[Result Formatting]
    H --> I[Output Delivery]
```

### Heatmap Data Processing

```mermaid
graph LR
    A[Access Event] --> B[Entry Creation]
    B --> C[Score Calculation]
    C --> D[Trend Analysis]
    D --> E[Decay Application]
    E --> F[Threshold Check]
    F -->|Keep| G[Graph Update]
    F -->|Prune| H[Entry Removal]
```

## Key Process Characteristics

### 1. Circuit Breaker Patterns
- **Visit Threshold**: Maximum 3 visits to same document per pathway
- **Depth Limit**: Configurable maximum traversal depth
- **Time Limit**: Maximum processing time per query
- **Memory Limit**: Maximum documents in memory simultaneously

### 2. Heatmap Parameters
- **Correlation**: 0.0-1.0 scale of citation usage probability
- **Usage Trend**: -1.0 to 1.0 scale of increasing/decreasing usage
- **Time Decay**: Exponential decay based on last access time
- **Prune Threshold**: Correlation < 0.3 and no usage in 30 days

### 3. Pathway Metrics
- **Relevance Score**: Weighted average of document relevance
- **Usage Frequency**: Total pathway accesses
- **Recent Usage**: Time since last access
- **Branch Points**: Number of decision points in pathway

## Performance Optimization Patterns

```mermaid
graph TD
    A[Query Received] --> B[Cache Check]
    B -->|Hit| C[Return Cached]
    B -->|Miss| D[Process Query]
    D --> E[Parallel Document Loading]
    E --> F[Incremental Heatmap Updates]
    F --> G[Pathway Compression]
    G --> H[Cache Results]
    H --> I[Return Response]
```

## Error Handling Flow

```mermaid
graph TD
    A[Error Detected] --> B[Log Error]
    B --> C[Notify Model]
    C --> D[Return Partial Results]
    D --> E[Attempt Recovery]
    E -->|Success| F[Continue Processing]
    E -->|Failure| G[Graceful Degradation]
```

## Conclusion

These flow diagrams illustrate the complete SigilML process architecture, from initial query handling through complex navigation patterns to final result delivery. The system's design emphasizes efficient knowledge traversal, intelligent pathway management, and robust error handling to create a reliable foundation for algorithmic information discovery.
