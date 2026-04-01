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
  version: "1.1"
  framework: OpenCode
  category: cli-tool
  last_updated: "2026-03-31"
---

# texforge CLI

CLI para compilar LaTeX a PDF. Usa [tectonic](https://tectonic-typesetting.github.io/) como motor interno — no requiere TeX Live ni MiKTeX, pero tectonic sí se instala como dependencia.

## Instalación

```bash
# Recomendado: instala texforge + tectonic en un paso
curl -fsSL https://raw.githubusercontent.com/JheisonMB/texforge/main/install.sh | sh

# Alternativa manual
cargo install tectonic
cargo install texforge
```

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

### `texforge build`

```bash
texforge build
```

Compila `main.tex` → PDF. Los errores se muestran con archivo, línea y sugerencia — nunca logs crudos de tectonic.

### `texforge fmt [--check]`

```bash
texforge fmt           # formatea en lugar
texforge fmt --check   # solo verifica, útil en CI
```

### `texforge check`

Linter estático — valida sin compilar. Detecta:
- Archivos `\input` faltantes
- Imágenes `\includegraphics` no encontradas
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
texforge template list
texforge template add apa-general       # desde registry (requiere internet la primera vez)
texforge template add <url>             # desde GitHub o URL directa
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

## Flujo típico

```bash
texforge new mi-documento
cd mi-documento
# editar main.tex y sections/
texforge check    # detectar errores antes de compilar
texforge fmt      # formatear
texforge build    # compilar a PDF
```

## Si `texforge build` falla

1. Correr `texforge check` primero — resuelve la mayoría de errores sin compilar
2. Verificar que tectonic esté instalado: `tectonic --version`
3. Si el error es de tectonic (paquete LaTeX faltante), tectonic lo descarga automáticamente en el primer build — verificar conexión a internet
4. Para errores de sintaxis LaTeX, el output de `texforge build` indica archivo y línea exacta
