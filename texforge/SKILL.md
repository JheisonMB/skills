---
name: texforge
description: >
  CLI tool for compiling LaTeX documents to PDF without TeX Live, MiKTeX, or any external LaTeX distribution.
  Use this skill whenever the user wants to create a LaTeX project, compile .tex files to PDF, format or lint
  LaTeX documents, manage templates, or work with the texforge CLI. Activate when the user mentions
  "texforge new", "texforge build", "texforge fmt", "texforge check", "texforge init", "texforge template",
  creating a thesis or academic document, compiling LaTeX without installing TeX Live, using tectonic as a
  LaTeX engine, project.toml configuration, or any workflow involving .tex files and the texforge tool.
license: MIT
metadata:
  author: jheison.martinez
  version: "1.4"
  framework: OpenCode
  category: cli-tool
  last_updated: "2026-04-03"
---

# texforge CLI

CLI para compilar LaTeX a PDF. Usa [tectonic](https://tectonic-typesetting.github.io/) como motor interno — no requiere TeX Live ni MiKTeX. Tectonic se instala automáticamente en el primer `texforge build`.

## Instalación

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/JheisonMB/texforge/main/install.sh | sh
```

```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/JheisonMB/texforge/main/install.ps1 | iex
```

```bash
# Via cargo
cargo install texforge
```

Tectonic se descarga e instala automáticamente en `~/.texforge/bin/` la primera vez que se ejecuta `texforge build`. No se requiere ningún paso adicional.

## Comandos

### `texforge new <name>`

```bash
texforge new mi-tesis                 # template "general" (embebido, funciona offline)
texforge new mi-tesis -t apa-general  # template específico
```

Estructura generada:
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

### `texforge init`

Wizard interactivo. Si detecta un `.tex` con `\documentclass`, ofrece migrar el proyecto existente. Si no, guía la creación de uno nuevo pidiendo nombre y template.

```bash
# En un directorio vacío — crea proyecto nuevo
cd mis-documentos/
texforge init

# En un proyecto LaTeX existente — migra
cd mi-tesis-existente/
texforge init
# Detectado: main.tex, refs.bib
# Pide titulo y autor, genera project.toml
```

Después de `init`, todos los comandos (`build`, `fmt`, `check`) funcionan normalmente.

### `texforge build`

```bash
texforge build
```

Compila `main.tex` → PDF en `build/`. Los errores se muestran con archivo, línea y sugerencia — nunca logs crudos de tectonic.

Antes de compilar, intercepta entornos de diagramas embebidos, los renderiza, y trabaja sobre copias en `build/` — los `.tex` originales nunca se modifican.

### `texforge clean`

```bash
texforge clean  # elimina build/ (PDF, logs, diagramas renderizados)
```

### Diagramas embebidos — Mermaid

```latex
% Sin opciones (defaults: width=\linewidth, pos=H, sin caption)
\begin{mermaid}
flowchart LR
  A[Input] --> B[Process] --> C[Output]
\end{mermaid}

% Con opciones
\begin{mermaid}[width=0.6\linewidth, caption=Flujo del sistema, pos=t]
flowchart TD
  X --> Y --> Z
\end{mermaid}
```

Renderizado a PNG en Rust puro — sin browser, sin Node.js, sin Inkscape.

| Opción | Default | Descripción |
|---|---|---|
| `width` | `\linewidth` | Ancho de la imagen |
| `pos` | `H` | Posición del figure (`H`, `t`, `b`, `h`, `p`) |
| `caption` | _(ninguno)_ | Pie de figura |

### Diagramas embebidos — Graphviz / DOT

```latex
\begin{graphviz}[caption=Pipeline, width=0.8\linewidth]
digraph G {
  rankdir=LR
  A -> B -> C
  B -> D
}
\end{graphviz}
```

Mismas opciones que mermaid. Renderizado via `layout-rs` — Rust puro, sin binario `dot` externo.

### `texforge fmt [--check]`

```bash
texforge fmt           # formatea en lugar
texforge fmt --check   # solo verifica, útil en CI
```

### `texforge check`

Linter estático — valida sin compilar. Detecta:
- Archivos `\input` faltantes
- Imágenes `\includegraphics` no encontradas
- Archivos `\lstinputlisting` no encontrados
- Archivos `\inputminted{lang}{file}` no encontrados
- Claves `\cite` no definidas en el `.bib`
- Pares `\ref`/`\label` rotos
- Entornos sin cerrar

```
ERROR [main.tex:47]
  \includegraphics{missing.png} — file not found

ERROR [main.tex:12]
  \cite{smith2020} — key not found in .bib
```

### `texforge template`

```bash
texforge template list               # lista templates instalados localmente
texforge template list --all         # lista instalados + disponibles en el registry remoto
texforge template add apa-general    # descarga desde registry
texforge template remove apa-general
texforge template validate apa-general
```

Templates disponibles:

| Template | Descripción |
|---|---|
| `general` | Artículo genérico (embebido, offline) |
| `apa-general` | Reporte APA 7ma edición |
| `apa-unisalle` | Tesis Universidad de La Salle |
| `ieee` | Paper IEEE |
| `letter` | Correspondencia formal en español |

## Flujo típico — proyecto nuevo

```bash
texforge new mi-documento
cd mi-documento
texforge check    # detectar errores antes de compilar
texforge fmt      # formatear
texforge build    # compilar a PDF
```

## Flujo típico — proyecto existente

```bash
cd mi-proyecto-latex/
texforge init     # genera project.toml detectando entry y bib
texforge check
texforge build
```

## Si `texforge build` falla

1. Correr `texforge check` primero — resuelve la mayoría de errores sin compilar
2. Si es el primer build, tectonic se está descargando — verificar conexión a internet
3. Para errores de sintaxis LaTeX, el output indica archivo y línea exacta
