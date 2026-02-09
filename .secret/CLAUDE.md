% CONTEXT: sigil-directive fragment (use \usepackage{sigil-directive} for compilable documents)

\begin{directive}
  \rootmemory{Update root CLAUDE.md with architecture information as learned. Annotate status on all entries.}
  \filememory{Maintain CLAUDE.md at each component location. Document files, functions, and interactions. Annotate status.}
  \clarification{When asked to clarify: ask substantive questions iteratively until high confidence, then proceed. Avoid trivial or confirmation-seeking questions.}
  \unity{Replicate this directive block in all CLAUDE.md files. If not in LaTeX environment format, refactor to match.}
\end{directive}

\begin{component}[name=secret, path=.secret/]
  \description{Internal documentation, design notes, and implementation planning}

  \begin{files}[status=implemented]
    \file[name=notes, status=implemented]{
      Project knowledge base; high-level overview of SigilML concepts, expansion modes, output formats, and implementation details
    }
    \file[name=navigation-system.md, status=implemented]{
      Comprehensive navigation system specification; citation network design, expansion modes, pathway tracking, heatmap generation, Paris travel guide use case
    }
    \file[name=process-flow.md, status=implemented]{
      Mermaid diagrams for all system flows: initialisation, navigation, pathway management, model interaction, circuit breaker logic
    }
    \file[name=roadmap.json, status=implemented]{
      JSON roadmap with 7 milestones and 21 tasks; dependency graph for implementation order
    }
    \file[name=interpreter-plan.md, status=implemented]{
      Detailed C interpreter implementation plan v2.0 (clarified); 10 phases covering lexer, parser, expansion engine, circuit breaker, streaming output formatter, pathway tracking with syllogistic transformation, embedded heatmap storage with webhook support, HTTP fetching with bearer auth, Python bindings with iterator streaming, and shared library build system (libsigilml.so)
    }
    \file[name=.studio.sml, status=implemented]{
      Studio configuration file
    }
  \end{files}

  \begin{relationships}
    \relationship[from=interpreter-plan.md, to=roadmap.json]{
      Implementation plan expands roadmap milestones into detailed specifications
    }
    \relationship[from=interpreter-plan.md, to=navigation-system.md]{
      Plan implements navigation system design
    }
    \relationship[from=interpreter-plan.md, to=process-flow.md]{
      Plan follows process flows defined in diagrams
    }
  \end{relationships}
\end{component}
