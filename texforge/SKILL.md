---
name: texforge
description: >
  CLI tool for compiling LaTeX documents to PDF without TeX Live, MiKTeX, or any external LaTeX distribution.
  Use this skill whenever the user wants to create a LaTeX project, compile .tex files to PDF, format or lint
  LaTeX documents, manage templates, or work with the texforge CLI. Activate when the user mentions
  "texforge new", "texforge build", "texforge fmt", "texforge check", "texforge template", creating a thesis
  or academic document, compiling LaTeX without installing TeX Live, using tectonic as a LaTeX engine,
  project.toml configuration, or any workflow involving .tex files and the texforge tool.
license: MIT
metadata:
  author: jheison.martinez
  version: "1.0"
  framework: OpenCode
  category: cli-tool
  last_updated: "2026-03-31"
---

# texforge CLI

Self-contained LaTeX to PDF compiler. One binary, zero external dependencies. The agent writes `.tex`, texforge compiles.

---

## Installation

```bash
# Quick install (installs texforge + tectonic)
curl -fsSL https://raw.githubusercontent.com/JheisonMB/texforge/main/install.sh | sh

# Or via cargo
cargo install texforge
cargo install tectonic
```

---

## Commands

### `texforge new <name>`

Creates a new project from a template.

```bash
texforge new mi-tesis                 # uses "general" template (default, embedded)
texforge new mi-tesis -t apa-general  # uses a specific template
```

Generated structure:
```
mi-tesis/
├── project.toml
├── main.tex
├── sections/body.tex
├── bib/references.bib
└── assets/images/
```

`project.toml`:
```toml
[documento]
titulo = "mi-tesis"
autor = "Author"
template = "general"

[compilacion]
entry = "main.tex"
bibliografia = "bib/references.bib"
```

### `texforge build`

Compiles to PDF. Run from the project directory.

```bash
texforge build
```

Reads `project.toml` → assembles document → compiles with tectonic → PDF. Errors shown cleanly with file, line, and suggestion — never raw tectonic logs.

### `texforge fmt [--check]`

Formats `.tex` files (inspired by `rustfmt`).

```bash
texforge fmt           # format in place
texforge fmt --check   # check only, CI-friendly
```

Normalizes: 2-space indentation inside environments, collapsed blank lines, aligned `\begin{}`/`\end{}` blocks.

### `texforge check`

Static linter — validates without compiling.

```bash
texforge check
```

Detects: missing `\input` files, missing `\includegraphics` images, undefined `\cite` keys, broken `\ref`/`\label` pairs, unclosed environments.

Error format:
```
ERROR [main.tex:47]
  \includegraphics{missing.png} — file not found

ERROR [main.tex:12]
  \cite{smith2020} — key not found in .bib
```

### `texforge template`

```bash
texforge template list                  # list installed templates
texforge template add apa-general       # download from registry
texforge template add <url>             # from GitHub or direct URL
texforge template remove apa-general
texforge template validate apa-general  # check tectonic compatibility
```

Templates are cached at `~/.texforge/templates/`.

| Template | Description |
|---|---|
| `general` | Generic article (default, embedded, works offline) |
| `apa-general` | APA 7th edition report |
| `apa-unisalle` | Universidad de La Salle thesis |
| `ieee` | IEEE journal paper |
| `letter` | Formal Spanish correspondence |

---

## Typical Workflow

```bash
texforge new mi-documento
cd mi-documento
# write content in main.tex / sections/
texforge check    # catch errors first
texforge fmt      # format
texforge build    # compile to PDF
```

---

## Notes

- If `texforge build` fails, run `texforge check` first — catches most issues without a full compile.
- The `general` template is embedded in the binary and works offline.
- Templates from the registry require internet on first download, then work offline.
