% Example SigilML file demonstrating the format
% This shows how citations and links would work

\begin{directive}
  \rootmemory{Track architecture decisions}
  \filememory{Document components at their locations}
  \clarification{Ask substantive questions before proceeding}
  \unity{Replicate this block in all CLAUDE.md files}
\end{directive}

\begin{project}[name=SigilML]
  \description{Executable Python module for interpreting .sml files}
  
  \begin{goals}[status=planned]
    \goal[name=citation-expansion]{Embed HTML links and expand/collapse citations}
    \goal[name=iterative-retrieval]{Enable RAG systems to traverse sigil links}
  \end{goals}
  
  \begin{component}[name=parser, status=planned]
    \description{Parse .sml files with LaTeX-based syntax}
    \file[name=parser.py]{Main parser implementation}
  \end{component}
\end{project}

% Example with citation
This is a passage with a \citation[id=cite1, author="Smith 2023", page="42"]{reference to research}\citation.

% Example with sigil link
See also the \sigil[target="related-document.sml", description="Related Work"]{related work}\sigil for more context.
