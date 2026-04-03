# Changelog - texforge Skill

## Version 1.4 (2026-04-03)

### Changed
- `texforge init` — now auto-detects mode: migrates if `.tex` with `\documentclass` found at root, otherwise launches new project wizard
- `texforge build --watch` — live session timer, build counter, last result only (no log accumulation), colored output, default debounce reduced to 2s

---

## Version 1.3 (2026-04-01)
### Added
- `texforge clean` — eliminar build/
- Assets mirrored via symlinks (Unix) / copy (Windows) — no file duplication
- Linter detecta `\begin{mermaid}` sin cerrar y `pos` inválido
- Tests unitarios para formatter, linter, diagrams y new command

---

## Version 1.2 (2026-04-01)

### Added
- Diagramas Mermaid embebidos en `.tex` con `\begin{mermaid}...\end{mermaid}`
- Opciones por diagrama: `width`, `pos`, `caption`
- Renderizado a PNG en Rust puro (mermaid-rs-renderer + resvg) — sin browser ni Node.js
- Los `.tex` originales nunca se modifican — se trabaja sobre copias en `build/`
- `texforge init` — migrar proyectos LaTeX existentes
- `texforge template list --all` — lista instalados + disponibles en registry remoto
- Linter detecta `\lstinputlisting` e `\inputminted` con archivos faltantes
- Auto-instalación de tectonic en primer build
- `install.ps1` para Windows (PowerShell)

---

## Version 1.0 (2026-03-31)

### Added
- `texforge init` command — migrar proyectos LaTeX existentes
- `texforge template list --all` — lista instalados + disponibles en registry remoto
- Linter detecta `\lstinputlisting` e `\inputminted` con archivos faltantes
- Auto-instalación de tectonic en primer build (sin pasos manuales)
- `install.ps1` para Windows (PowerShell)
- `install.sh` simplificado — ya no instala tectonic (lo maneja texforge)

### Changed
- Instalación: tectonic ya no es un paso separado
- Flujo de troubleshooting actualizado (sin `tectonic --version`)

---

## Version 1.0 (2026-03-31)

### Initial Release

First version of the texforge skill, created from the texforge v0.1.0 CLI project.
