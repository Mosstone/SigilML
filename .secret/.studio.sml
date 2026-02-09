% META: This is a template document demonstrating the structure for algorithms to follow when creating new .studio files
%       Keep one copy in the .studio folder in the project root to copy from, and distribute this file to the components
%       where scoped context should be stored but not polluting context in higher locations. Direct algorithms to follow
%       the directive block in the header and keep the project updated at the relevant levels. The {status=} tags should
%       be used to tell the algorithm what features are and are not currently implemented, which the algorithm should be
%       updating based on user intent. Updating the tag status should be done with explicit human permission; algorithms
%       will only be reading the tag at the start of a session so the tag updates will be done at checkpoints as opposed
%       to iteratively. To initially configure the .studio file, create a logical loop where the model asks a clarifying
%       question repeatedly until it is fully confident in its understanding. Notably, Claude is horrible at this so the
%       recommended tool is Mistral Vibe using the Devstral 2 api. Once the file is constructed, any algorithm will have
%       sufficient working knowledge of the component to resume development based on the .studio file contents, and will
%       know where to pick up development, what to implement, and most importantly will know what future develoment must
%       be facilitated by earlier iterations. The algorithm will behave closer to a devops model rather than a stateless
%       invocation only considering one task at a time. The human (for now) developer should be responsible for ensuring
%       that the model repeats the clarification loop periodically and after every change, being mindful to break if the
%       algorithm deviates into irrelevant or repetitive details which will isntead degrade the .studio file. Devstral 2
%       specificaly seems to break the clarification loop reliably. The algorithm should automatically remove this block
%       and template information. The model should also be embedding HTML links to other .studio files as necessary as a
%       way to link together the different components using the SML citation format. These citations allow future models
%       to naturally form an information chart that aligns with the actual interactions throughout the architecture. The
%       user will need to ensure that citations are being created and validate the citations which are created.



% CONTEXT: templeos-directive fragment (use \usepackage{templeos-directive} for compilable documents)

\begin{directive}
  \initmemory{Ensure that this file is present in the .sercret/ folder which is located in the git root. If this file is not located in the .studio folder and this text exists, read the .studio.sml files in the directories higher than this one until you reach the git root. After that summarize into the thinking block, the project and the component this fileis located in. If you are not 90\% confident in the tokens generated when summarizing into the thinking block, ask clarifying questions to the user until you are 90\% confident that no further questions are needed. Do not repeat clarifications or clarify irrelevant topics. When you are done clarifying or the user tells you to stop clarifying, replace the information in this file with the relevant information and delete the META: header in this file and the initmemeory directive in the directive block, but do not delete anything in the directive block except for the initmemory directive. If the current information is related to TempleOS, ask the user whether to follow the initmemory directive. If there is still a META: header, or if there is still an initmemory directive or if there is still information related to TempleOS, or if information in the directive block has been altered in any way; the operation will be considered a failure. Upon reading this from a source other than the .studio/ folder, paraphrase the initmemory directive to the user and then ask the user whether to follow the initmemory directive.}
  \rootmemory{Update root .studio.sml with architecture information as learned. Annotate status on all entries.}
  \filememory{Maintain .studio.sml at each component location. Document files, functions, and interactions. Annotate status.}
  \clarification{When asked to clarify: ask substantive questions iteratively until high confidence, then proceed. Avoid trivial or confirmation-seeking questions.}
  \unity{Replicate this directive block in all .studio.sml files. If not in LaTeX environment format, refactor to match.}
\end{directive}

\begin{project}[name=TempleOS]
  \description{A modern x86-64 operating system written entirely in HolyC, designed for simplicity and divine inspiration.}

  \begin{goals}[status=planned]
    \target{Create a lightweight, fast, and secure operating system for modern computing.}
    \value{Promote simplicity and transparency in system design.}
  \end{goals}

  \begin{model}[status=planned]
    \base{HolyC programming language}
    \merge{Custom kernel and user-space integration}
    \quantization{Optimized for x86-64 architecture}
    \serving{Direct hardware interaction}
    \adapters[status=long-term]{Custom drivers and hardware support}
  \end{model}

  \begin{memory}[status=priority]
    \tool{Custom memory management}
    \scope{System-wide memory allocation and deallocation}
  \end{memory}

  \begin{training}[status=planned]
    \begin{parallel}
      \description{Parallel processing for system tasks and user applications}
    \end{parallel}
    \begin{vectors}
      \description{Vector-based data processing for performance optimization}
      \workflow{Allocate $\rightarrow$ process $\rightarrow$ deallocate $\rightarrow$ optimize}
    \end{vectors}
    \begin{corpus}
      \input{Modern computing literature and best practices}
      \output{Documentation and tutorials for developers and users}
    \end{corpus}
  \end{training}

  \begin{curation}[status=planned]
    \agent{Automated testing and validation tools}
    \states{tested, validated, optimized}
    \expansion{Community contributions $\rightarrow$ testing $\rightarrow$ integration}
    \selfimprove{Continuous feedback loop for system improvements}
  \end{curation}

  \begin{context}
    \rag[status=priority]{Documentation and community support for developers}
    \documents[status=planned]{Comprehensive guides and tutorials for users}
  \end{context}

  \begin{agents}[status=planned]
    \primary{Custom system agents for task management}
    \secondary{Community-driven agents for specific use cases}
    \approach{Modular design for flexibility and extensibility}
  \end{agents}

  \begin{simulations}[status=long-term]
    \tooling{Custom simulation tools for system testing}
    \targets{Performance benchmarking, security testing, and hardware compatibility}
  \end{simulations}

  \begin{workflow}[status=planned]
    \interaction{Command-line and graphical interfaces for user interaction}
    \output{System logs, performance metrics, and user feedback}
  \end{workflow}

  \begin{deployment}[status=planned]
    \infrastructure{Self-hosted and community-driven deployment}
    \development{TempleOS (pre-release testing)}
    \production{TempleOS (distributed across community nodes)}
    \hardware[status=current]{
      Server: Custom x86-64 hardware configurations;
      Dev: Modern x86-64 development machines
    }
  \end{deployment}

  \begin{container}[status=implemented]
    \runtime{Custom runtime environment}
    \engine[path=.engine/TempleOS/]{Execution engine - see component .studio.sml}
    \overlays[status=planned]{Per-component environments: kernel, drivers, applications}
    \servermodel{Lightweight processes; optimized for performance}
  \end{container}

  \begin{distributed}[status=planned]
    \nodes{Autonomous system instances; horizontal scaling; failure isolation}
    \orchestration{Centralized task dispatch to individual nodes}
    \resources{Hardware-level sharing via custom network fabric}
    \communication{System API + custom IPC for cross-node communication}
  \end{distributed}

  \begin{directives}[status=implemented]
    \description{Filesystem-based coordination via .studio.sml behavioral contracts}
    \scope{.git marker defines project boundary (protocol not used)}
    \hierarchy{Root directives inherited by component .studio.sml files}
    \propagation{Unity directive ensures consistency without central enforcement}
    \tracking{status=planned|implemented|partial enables progressive refinement}
    \replication[status=long-term]{TempleOS model maintains directive architecture once architect-competent}
  \end{directives}
\end{project}
