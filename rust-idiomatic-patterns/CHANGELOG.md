# Changelog — rust-idiomatic-patterns

## Version 1.0 (2026-04-01)

### Initial Release

Skill creado a partir de experiencia real en proyectos Rust de producción.

#### Contenido

- **Ownership & Borrowing** — tabla de decisiones: cuándo `&T`, cuándo `String`, cuándo `Cow`
- **Errores** — `thiserror` para libs, `anyhow` para binarios, Fail Fast antes del trabajo costoso
- **Iteradores** — encadenar sin `collect()` intermedio, `filter_map`, `find`
- **Structs & Enums** — `let...else`, `Box<T>` para variantes grandes, enum sobre bool flags
- **SoC** — separar locate/install/orchestrate con ejemplo concreto
- **DRY** — unificar funciones con mismo esqueleto usando closures genéricas
- **Visibilidad** — `pub(crate)`, mover duplicados a `utils`
- **cfg** — plataformas sin `allow(unreachable_code)`
- **Tests** — naming descriptivo, `tempfile::TempDir`, un assert por test
- **Clippy** — 5 lints clave, comando correcto con `-D warnings`
- **Red Flags** — lista corta de lo que nunca hacer en producción
