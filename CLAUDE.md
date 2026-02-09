% CONTEXT: sigil-directive fragment (use \usepackage{sigil-directive} for compilable documents)

\begin{directive}
  \rootmemory{Update root CLAUDE.md with architecture information as learned. Annotate status on all entries.}
  \filememory{Maintain CLAUDE.md at each component location. Document files, functions, and interactions. Annotate status.}
  \clarification{When asked to clarify: ask substantive questions iteratively until high confidence, then proceed. Avoid trivial or confirmation-seeking questions.}
  \unity{Replicate this directive block in all CLAUDE.md files. If not in LaTeX environment format, refactor to match.}
\end{directive}

\begin{project}[name=SigilML]
  \description{Thin C-based interpreter as Python module for reading .sml files with expandable citations and hyperlinked knowledge retrieval}

  \begin{goals}[status=planned]
    \goal[name=citation-expansion]{Embed HTML links and passage information; expand or collapse citations on demand}
    \goal[name=iterative-retrieval]{Enable RAG systems to traverse sigil links indefinitely, akin to Wikipedia hyperlink navigation}
    \goal[name=portable-installation]{Distribute as OS-level package or Python module for broad compatibility}
    \goal[name=mcp-integration]{Add MCP API support for vector databases, event-driven agents, and external tooling}
    \goal[name=multi-language]{Provide Elixir and Rust interfaces alongside Python}
  \end{goals}

  \begin{model}[status=planned]
    \format{.sml files - SigilML markup with embedded citations and hyperlinks (LaTeX/XML hybrid)}
    \retrieval{Multi-pass: flat data $\rightarrow$ passage expansion $\rightarrow$ link traversal}
    \perspective{Wikipedia-style navigation where RAG provides starting point}
    \output{Raw sigil (recursive), XML (structure-preserving), plaintext (stripped)}
  \end{model}

  \begin{expansion}[status=planned]
    \mode[name=discard]{Links invisible; hyperlink text preserved; non-rich output}
    \mode[name=passage]{Links replaced with specific paragraph or object data}
    \mode[name=default]{Entire referenced document returned with citations intact}
    \override{Interpreter can override .sml specifications per invocation}
  \end{expansion}

  \begin{navigation}[status=planned]
    \description{Complete library navigation through citation network}
    \prevention{Circuit breaker logic prevents duplicate document reading and redirect loops}
    \pathway{Tracks navigation threads for single-step replay}
    \heatmap{Time-decay scoring based on real usage patterns}
    \pagerank{Optional PageRank integration for relevance weighting}
  \end{navigation}

  \begin{api}[status=planned]
    \behaviour{Fresh fetch on each request; no caching}
    \sources{Database queries, web searches, AI model calls, live data (weather, etc.)}
    \embedding{API responses embedded directly in output}
  \end{api}

  \begin{interpreter}[status=planned]
    \language{C (core) + Python (module interface)}
    \integration{Python C API baked into module}
    \interface{Executable module}
    \dependencies{Python C API, libcurl (HTTP)}
    \arguments{
      Arg1: expansion mode (accept passage, pull entire file, collapse to hyperlink, strip citations);
      Arg2: output format (SML, XML, plaintext);
      Arg3: input type (SML, JSON, XML)
    }
  \end{interpreter}

  \begin{workflow}[status=planned]
    \usecase[name=flat-retrieval]{Initial search returns compact data with citation markers}
    \usecase[name=expansion]{Targeted expansion of specific citations for deeper context}
    \usecase[name=traversal]{Follow returned sigil links to related documents recursively}
    \usecase[name=embedding]{Use as data pointers in vector databases and agent systems}
    \usecase[name=pathway-reuse]{Replay stored navigation threads in single step}
    \usecase[name=syllogistic]{Transform pathways between analogous concepts (Paris$\rightarrow$France becomes Rome$\rightarrow$Italy)}
  \end{workflow}

  \begin{deployment}[status=planned]
    \target{Python-compatible architectures}
    \distribution{PyPI package, OS-level installation, embedded module}
    \integration{MCP API for external tool compatibility}
    \bindings{Elixir, Rust interfaces}
  \end{deployment}

  \begin{components}[status=partial]
    \component[name=spec, path=.spec/, status=implemented]{
      Formal schema specification for Sigil directive format (LaTeX grammar, JSON Schema, conversion rules)
    }
    \component[name=interpreter, path=src/sigilml/, status=planned]{
      C-based interpreter with Python C API bindings;
      Files: interpreter.c, bindings.c, __init__.py
    }
    \component[name=mcp, path=src/mcp/, status=planned]{
      MCP API adapter for vector database and agent integration
    }
    \component[name=tests, path=tests/, status=planned]{
      Test suite: test_interpreter.py, test_expansion.py, test_api.py, test_pathway.py, test_relevance.py
    }
  \end{components}

  \begin{files}[status=partial]
    \file[name=CLAUDE.md, status=implemented]{This file - root project documentation}
    \file[name=example.sml, status=implemented]{Example .sml format demonstrating citations and sigil links}
    \file[name=.spec/, status=planned]{Schema specifications (directory not yet created)}
    \file[name=.secret/, status=implemented]{Internal notes, roadmap, navigation system design, and interpreter plan}
    \file[name=.secret/interpreter-plan.md, status=implemented]{Detailed 10-phase C interpreter implementation plan}
  \end{files}

  \begin{directives}[status=implemented]
    \directive[name=rootmemory]{Maintain architecture overview at project root}
    \directive[name=filememory]{Document components at their locations}
    \directive[name=clarification]{Ask substantive questions before proceeding}
    \directive[name=unity]{Propagate directive block to all CLAUDE.md files}
  \end{directives}
\end{project}
