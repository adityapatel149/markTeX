# MarkTeX

MarkTeX is a lightweight domain-specific language and compiler written in Haskell that converts a Markdown-inspired document format into LaTeX and PDF output.

The project combines ideas from DSL design, language design, parsing, compiler construction, abstract syntax trees, semantic validation, and code generation. MarkTeX is designed to make academic writing easier by preserving Markdown's readability while supporting LaTeX-style structure, citations, labels, references, and document compilation.

---

## Overview

Writing LaTeX directly can be powerful but verbose. Markdown is easier to read and write, but it lacks many features commonly needed in academic and technical documents, such as citations, labels, references, and structured LaTeX output.

MarkTeX bridges that gap.

It lets users write documents in a simple Markdown-like syntax, then processes the document through a compiler-style pipeline:

```text
MarkTeX Input
     |
     v
Parser
     |
     v
Abstract Syntax Tree
     |
     v
Validation
     |
     v
LaTeX Generation
     |
     v
PDF Compilation
```
---

## Requirements

To run MarkTeX, install the following:

### Haskell

You need GHC and `runghc`.

Recommended installation options:

- GHCup
- Stack
- Cabal

### Haskell Packages

The project uses:

- `parsec`
- `containers`
- `filepath`
- `process`

Depending on your setup, these may already be available with your GHC installation.

### LaTeX

To generate PDFs, install a LaTeX distribution that includes:

- `pdflatex`
- `bibtex`

Recommended distributions:

- TeX Live
- MiKTeX
- MacTeX

---

## How to Run

### 1. Clone the Repository

```bash
git clone https://github.com/adityapatel149/markTeX/
cd markTeX
```

### 2. Prepare an Input File

Create an input file such as:

```text
example.md
```


### 3. Run MarkTeX

To generate a `.tex` file using the default output filename:

```bash
runghc Main.hs example.md
```

This creates:

```text
example.tex
example.pdf
```

To specify the output `.tex` filename:

```bash
runghc Main.hs example.md output.tex
```

---

## Bibliography Support

MarkTeX emits:

```latex
\bibliographystyle{plain}
\bibliography{references}
```

Therefore, if your document uses citations, include a `references.bib` file in the same directory.

---

## Features

### Markdown-Inspired Syntax

MarkTeX supports a clean, readable input format inspired by Markdown.

Supported block-level constructs include:

- Document metadata
- Paragraphs
- Headers
- Unordered lists
- Nested list content
- Code blocks

Supported inline constructs include:

- Italic text
- Bold text
- Underlined text
- Strikethrough text
- Nested formatting
- Citations
- Internal references
- Escaped special characters

---

## Example MarkTeX Input

```markdown
% Title: My ~~Complex~~ **_*Simple*_ Paper**
% Author: \~John\_Doe
% Date: 2026

# Introduction {#sec:intro}

This is *italic*, **bold**, _underline_, and ~~strike~~.

See [](#sec:intro) and the [features section](#sec:features).

## Features {#sec:features}

Here is a citation: [@paper1, paper_2026]


```

---

## Example LaTeX Output

MarkTeX generates LaTeX similar to the following:

```latex
\documentclass{article}
\usepackage[utf8]{inputenc}
\usepackage{hyperref}
\usepackage{cleveref}
\usepackage[margin=1in]{geometry}
\usepackage[normalem]{ulem}

\title{My \sout{Complex} \textbf{\underline{\textit{Simple}} Paper}}
\author{\textasciitilde{}John\_Doe}
\date{2026}

\begin{document}

\maketitle

\section{Introduction }\label{sec:intro}

This is \textit{italic}, \textbf{bold}, \underline{underline}, and \sout{strike}.

See \Cref{sec:intro} and the \hyperref[sec:features]{features section} (\Cref{sec:features}).

\bibliographystyle{plain}
\bibliography{references}
\end{document}
```

---

## Supported Syntax

### Metadata

Metadata lines begin with `%` and appear at the top of the document.

```markdown
% Title: My Paper
% Author: Jane Doe
% Date: 2026
```

Supported metadata fields:

```text
Title
Author
Date
```

These are rendered into LaTeX using:

```latex
\title{}
\author{}
\date{}
```

If any metadata is present, MarkTeX automatically emits `\maketitle`.

---

### Headers

Headers use Markdown-style `#` syntax.

```markdown
# Introduction {#sec:intro}
## Background {#sec:background}
### Details {#sec:details}
```

Header levels are mapped to LaTeX sectioning commands:

| MarkTeX | LaTeX |
|---|---|
| `#` | `\section` |
| `##` | `\subsection` |
| `###` | `\subsubsection` |
| `####` | `\paragraph` |
| `#####` and above | `\subparagraph` |

Optional labels can be attached to headers:

```markdown
# Introduction {#sec:intro}
```

This becomes:

```latex
\section{Introduction}\label{sec:intro}
```

---

### Inline Formatting

MarkTeX supports several inline formatting constructs.

```markdown
*italic*
**bold**
_underline_
~~strike~~
```

These compile to:

```latex
\textit{italic}
\textbf{bold}
\underline{underline}
\sout{strike}
```

Nested formatting is also supported:

```markdown
**bold with *italic and _underline_ inside***
```

---

### Citations

Citations use a compact citation syntax:

```markdown
[@paper1]
[@paper1, paper_2026]
```

These compile to:

```latex
\cite{paper1}
\cite{paper1,paper_2026}
```

Citation keys may contain letters, numbers, underscores, hyphens, and colons.

---

### References

References use label-based linking syntax.

```markdown
[](#sec:intro)
[Introduction](#sec:intro)
[these sections](#sec:intro, sec:background)
```

MarkTeX supports both unnamed and named references.

An unnamed reference:

```markdown
[](#sec:intro)
```

becomes:

```latex
\Cref{sec:intro}
```

A named reference:

```markdown
[Introduction](#sec:intro)
```

becomes:

```latex
\hyperref[sec:intro]{Introduction} (\Cref{sec:intro})
```

Multiple-label references are also supported:

```markdown
[these sections](#sec:intro, sec:background)
```

---

### Unordered Lists

Lists use Markdown-style dash syntax.

```markdown
- First item
- Second item
- Third item
```

These compile to LaTeX `itemize` environments.

```latex
\begin{itemize}
\item First item
\item Second item
\item Third item
\end{itemize}
```

Indented blocks inside list items are also supported.

```markdown
- Third list item
  Second paragraph inside third item
  ## Header inside list item {#sec:list-header}
  More text after header
```

---

### Code Blocks

Code blocks use triple backticks.

````markdown
```haskell
main = putStrLn "Hello, MarkTeX!"
```
````

Code blocks are rendered using LaTeX `verbatim`, meaning inline markup inside the code block is not parsed.

```latex
\begin{verbatim}
main = putStrLn "Hello, MarkTeX!"
\end{verbatim}
```

---

### Escaped Characters

MarkTeX supports escaping special characters with a backslash.

```markdown
\# \$ \% \& \_ \{ \} \~ \^ \\ \[ \]
```

These are safely rendered into LaTeX-safe output.

---

## Validation

Before rendering LaTeX, MarkTeX performs semantic validation.

### Duplicate Label Detection

If the same label is defined more than once, MarkTeX reports an error.

```markdown
# Introduction {#sec:intro}
# Duplicate Introduction {#sec:intro}
```

Example error:

```text
Duplicate label: sec:intro
```

### Undefined Reference Detection

If a reference points to a label that does not exist, MarkTeX reports an error.

```markdown
See [missing section](#sec:missing)
```

Example error:

```text
Undefined reference: sec:missing
```

This validation step helps catch document errors before LaTeX generation.

---

## Project Structure

A recommended repository structure is:

```text
marktex/
├── Main.hs
├── MarkTex/
│   ├── AST.hs
│   ├── Parser.hs
│   └── Render/
│       └── LaTeX.hs
├── examples/
│   ├── marktex_sample.md
│   └── marktex_sample.tex
│   └── marktex_sample.pdf
│   └── references.bib
└── README.md
```

### Main Components

#### `Main.hs`

The command-line entry point.

Responsibilities:

- Reads command-line arguments
- Parses the input MarkTeX file
- Renders the AST to LaTeX
- Writes the generated `.tex` file
- Runs `pdflatex`
- Runs `bibtex`
- Re-runs `pdflatex` to resolve references

#### `MarkTex/AST.hs`

Defines the core abstract syntax tree used by the compiler.

Main AST types:

- `Document`
- `Block`
- `Inline`
- `Label`
- `CitationKey`

#### `MarkTex/Parser.hs`

Implements the parser using Parsec.

Responsibilities:

- Parse metadata
- Parse block-level syntax
- Parse inline formatting
- Parse citations
- Parse references
- Parse escaped characters
- Convert source text into the AST

#### `MarkTex/Render/LaTeX.hs`

Implements validation and LaTeX code generation.

Responsibilities:

- Collect labels
- Detect duplicate labels
- Validate references
- Escape LaTeX special characters
- Render blocks and inline elements
- Generate complete LaTeX documents


---


## Compiler Pipeline

MarkTeX follows a compiler-inspired architecture.

### 1. Lexical and Syntactic Parsing

The parser reads the MarkTeX source file and recognizes document constructs such as metadata, headers, paragraphs, lists, code blocks, citations, and references.

### 2. AST Construction

The parsed document is represented using strongly typed Haskell data structures.

Example:

```haskell
data Document = Document
  { docTitle  :: Maybe [Inline]
  , docAuthor :: Maybe [Inline]
  , docDate   :: Maybe [Inline]
  , docBlocks :: [Block]
  }
```

### 3. Semantic Validation

Before rendering, MarkTeX validates document correctness.

It checks:

- Whether labels are unique
- Whether references point to existing labels

### 4. Code Generation

After validation, MarkTeX generates LaTeX code from the AST.

### 5. PDF Compilation

The generated LaTeX file is compiled using:

```bash
pdflatex
bibtex
pdflatex
pdflatex
```

This ensures that citations and cross-references are resolved correctly.

---

## Design Goals

MarkTeX was built with the following goals:

- Provide a readable writing format for academic documents
- Preserve useful LaTeX features such as citations and references
- Demonstrate DSL design in Haskell
- Demonstrate compiler design concepts through a practical project
- Use a typed AST to represent document structure
- Validate documents before rendering
- Generate clean, compilable LaTeX output

---

## Current Limitations

MarkTeX is intentionally lightweight and educational. Some limitations include:

- Only unordered lists are currently supported
- Tables are not supported yet
- Images are not supported yet
- Math environments are not supported yet
- The bibliography file is assumed to be named `references.bib`
- The renderer always emits bibliography commands
- The CLI currently uses `runghc` rather than a packaged executable

---


## Educational Concepts Demonstrated

This project demonstrates several important programming language and compiler design concepts:

- Domain-specific language design
- Concrete syntax design
- Parser combinators
- Recursive descent parsing
- Abstract syntax trees
- Semantic analysis
- Symbol table construction
- Reference validation
- Code generation
- Pretty-printing target language output
- CLI-based compiler workflow

It also demonstrates functional programming concepts in Haskell, including:

- Algebraic data types
- Pattern matching
- Recursive data structures
- Pure rendering functions
- `Either`-based error handling
- Modular program organization

---



## License

This project is intended for educational and academic use. Add your preferred open-source license here.

Example:

```text
MIT License
```
