# rust-idiomatic-patterns — Agent Skill

Decisiones idiomáticas de Rust para escribir código limpio, seguro y eficiente. Destilado de experiencia real en proyectos de producción.

## Overview

Este skill no es el libro de Rust — es la destilación de las reglas que realmente importan en el día a día: cuándo clonar, cómo manejar errores, cómo aplicar DRY/SoC/Fail-Fast en Rust, y qué nunca hacer en producción.

## Installation

```bash
npx skills add https://github.com/jheisonmb/skills --skill rust-idiomatic-patterns
```

## What's Included

- **SKILL.md** — Cheatsheet de decisiones: ownership, errores, iteradores, SoC, DRY, tests, clippy, red flags

## Key Features

- ✅ Tablas de decisión para ownership/borrowing
- ✅ Fail Fast — validar antes de trabajar
- ✅ SoC — separar locate/install/orchestrate
- ✅ DRY — unificar con genéricos y closures
- ✅ cfg sin `allow(unreachable_code)`
- ✅ Tests con tempfile, nombres descriptivos
- ✅ Red flags concretos de producción

## When to Use

Activar cuando escribiendo, revisando o refactorizando código Rust. Especialmente útil en:
- Decisiones de ownership (¿`&str` o `String`?)
- Manejo de errores (`anyhow` vs `thiserror`)
- Refactor DRY (dos funciones con el mismo esqueleto)
- Code review buscando anti-patrones
- Configurar clippy correctamente

## Skill Structure

```
rust-idiomatic-patterns/
├── SKILL.md       # Cheatsheet completo
├── README.md      # Este archivo
├── CHANGELOG.md   # Historial de versiones
└── LICENSE        # MIT
```

## License

MIT — See LICENSE file for details

## Metadata

- **Version:** 1.0
- **Language:** Rust
- **Category:** Language Patterns
- **Author:** jheison.martinez
- **Last Updated:** 2026-04-01
