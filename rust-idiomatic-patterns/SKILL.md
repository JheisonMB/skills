---
name: rust-idiomatic-patterns
description: >
  Decisiones idiomáticas de Rust para escribir código limpio, seguro y eficiente.
  Destilado de experiencia real en proyectos de producción — no el libro de Rust,
  sino las reglas que realmente importan en el día a día.

  Activar cuando:
  - Escribiendo código Rust nuevo (funciones, structs, enums, módulos)
  - Revisando o refactorizando código Rust existente
  - Decidiendo entre &T vs String, clone vs borrow, dyn vs impl
  - Manejando errores con Result/Option
  - Diseñando APIs públicas o internas
  - Aplicando DRY, YAGNI, SoC, Fail-Fast en Rust
  - Escribiendo tests unitarios
  - Resolviendo warnings de clippy

  ACTIVAR cuando el usuario menciona:
  "Rust", "cargo", "ownership", "borrow", "lifetime", "Result", "Option",
  "unwrap", "clone", "trait", "impl", "enum", "struct", "clippy", "anyhow",
  "thiserror", "iterator", "flatMap", "collect", "Vec", "HashMap",
  "refactor Rust", "idiomatic", "best practice Rust", "code review Rust",
  "DRY Rust", "SoC Rust", "Fail Fast Rust".

  NO USAR para: Java, Python, JavaScript, o cualquier lenguaje que no sea Rust.
license: MIT
metadata:
  author: jheison.martinez
  version: "1.0"
  language: Rust
  category: language-patterns
  last_updated: "2026-04-01"
---

# Rust Idiomatic Patterns

Reglas accionables extraídas de experiencia real. Sin teoría — solo decisiones.

---

## Ownership & Borrowing

**Regla de oro: nunca `.clone()` sin que el compilador lo exija.**

| Situación | Usar |
|---|---|
| Parámetro que solo lees | `&T`, `&str`, `&[T]` |
| Parámetro que necesitas poseer | `T`, `String`, `Vec<T>` |
| Retorno que produces | `String`, `Vec<T>` |
| Retorno que lees de `self` | `&T`, `&str` |
| Ownership ambiguo | `Cow<'_, T>` |
| Tipo ≤ 24 bytes + Copy | pasar por valor |

Si clonás, preguntate si el diseño está mal.

---

## Errores

```rust
// Librería — enum tipado con thiserror
#[derive(thiserror::Error, Debug)]
enum AppError {
    #[error("not found: {0}")]
    NotFound(String),
}

// Binario/CLI — anyhow con contexto
fn execute() -> anyhow::Result<()> {
    do_thing().context("Failed to do thing")?;
    Ok(())
}
```

- `unwrap()` / `expect()` solo en tests
- `?` sobre `match` para propagar
- `.with_context(|| format!(...))` cuando el mensaje necesita datos dinámicos
- **Fail Fast**: validar entradas al inicio, antes de hacer trabajo costoso

```rust
// ✅ Fail Fast — validar primero
fn render_env(content: &str, pos: &str) -> Result<String> {
    if !["H", "t", "b", "h", "p"].contains(&pos) {
        anyhow::bail!("Invalid pos='{}' — valid: H, t, b, h, p", pos);
    }
    // trabajo costoso después
    let png = render_to_png(content)?;
    ...
}
```

---

## Iteradores

```rust
// ✅ encadenar directamente
let total: u32 = items.iter()
    .filter(|x| x.active)
    .map(|x| x.value)
    .sum();

// ❌ collect() intermedio innecesario
let filtered: Vec<_> = items.iter().filter(...).collect();
let total: u32 = filtered.iter().map(...).sum();
```

- `.iter()` para Copy types, `.into_iter()` cuando necesitas ownership
- `filter_map` > `filter` + `map` separados
- `.find(|p| p.exists())` > loop manual con `break`

---

## Structs & Enums

```rust
// let...else para fail-fast sin anidamiento
let Some(value) = maybe_value else { return; };

// Enum sobre bool flags cuando hay más de 2 estados
enum Status { Active, Inactive, Pending }  // ✅
struct Item { is_active: bool }             // ❌

// Box<T> para variantes grandes
enum Event {
    Small(u32),
    Large(Box<BigData>),  // evita large_enum_variant warning
}
```

---

## Funciones & SoC

Una función = una responsabilidad. Si el nombre necesita "y" o "or", dividir.

```rust
// ✅ separado — cada función hace una cosa
fn locate_binary() -> Option<PathBuf> { ... }
fn install_binary(dest: &Path) -> Result<()> { ... }
fn find_or_install() -> Result<PathBuf> {
    if let Some(p) = locate_binary() { return Ok(p); }
    let dest = managed_path()?;
    install_binary(&dest)?;
    Ok(dest)
}

// ❌ mezclado — busca + instala + reporta + decide
fn find_tectonic() -> Result<PathBuf> { ... }
```

---

## DRY — Unificar con genéricos y closures

Cuando dos funciones tienen el mismo esqueleto con lógica diferente en el medio:

```rust
// ❌ duplicado
fn detect_entry(root: &Path) -> Option<String> {
    for entry in WalkDir::new(root).max_depth(2) { ... }
}
fn detect_bib(root: &Path) -> Option<String> {
    for entry in WalkDir::new(root).max_depth(3) { ... }
}

// ✅ unificado con closure
fn find_file_by(root: &Path, depth: usize, pred: impl Fn(&Path) -> bool) -> Option<String> {
    WalkDir::new(root).max_depth(depth).into_iter()
        .filter_map(|e| e.ok())
        .find(|e| e.path().is_file() && pred(e.path()))
        .and_then(|e| e.path().strip_prefix(root).ok()
            .map(|p| p.to_string_lossy().to_string()))
}

fn detect_entry(root: &Path) -> Option<String> {
    find_file_by(root, 2, |p| {
        p.extension() == Some("tex".as_ref())
            && fs::read_to_string(p).map(|c| c.contains("\\documentclass")).unwrap_or(false)
    })
}
```

---

## Visibilidad & Módulos

- `pub(crate)` para exponer entre módulos internos sin API pública
- Mover utilidades compartidas a `utils/mod.rs` — no duplicar entre módulos
- Si dos módulos tienen la misma función privada, pertenece a `utils`

```rust
// ❌ resolve_tex_path en linter/mod.rs Y resolve_tex en diagrams/mod.rs
// ✅ resolve_tex_path en utils/mod.rs, importada donde se necesite
```

---

## cfg sin unreachable_code

```rust
// ✅ — sin allow(unreachable_code)
#[cfg(unix)]
fn which_cmd() -> &'static str { "which" }
#[cfg(not(unix))]
fn which_cmd() -> &'static str { "where" }

// ✅ — para plataformas no soportadas
#[cfg(not(any(
    all(target_os = "linux", target_arch = "x86_64"),
    all(target_os = "macos", target_arch = "aarch64"),
    // ...
)))]
fn current_target() -> Result<&'static str> {
    anyhow::bail!("Unsupported platform")
}
```

---

## Tests

```rust
// Nombre: qué_hace_cuando_condición
#[test]
fn validate_name_returns_error_when_empty() { ... }

// Un assert por test cuando sea posible
// tempfile::TempDir para tests con filesystem
// No mockear lo que podés usar real
#[test]
fn lint_detects_missing_includegraphics() {
    let dir = TempDir::new().unwrap();
    fs::write(dir.path().join("main.tex"), "\\includegraphics{missing.png}").unwrap();
    let errors = lint(dir.path(), "main.tex", None).unwrap();
    assert!(errors.iter().any(|e| e.message.contains("missing.png")));
}
```

---

## Clippy — Correr siempre

```bash
cargo clippy --all-targets -- -D warnings
cargo fmt --check
```

| Lint | Detecta |
|---|---|
| `redundant_clone` | `.clone()` innecesario |
| `needless_pass_by_value` | parámetro que debería ser `&T` |
| `large_enum_variant` | variante que debería ser `Box<T>` |
| `manual_let_else` | `match` que debería ser `let...else` |
| `doc_markdown` | backticks faltantes en doc comments |

---

## Red Flags — Nunca en producción

- `unwrap()` fuera de tests
- `.clone()` en loops
- `collect()` intermedio sin necesidad
- Función que hace más de una cosa
- Duplicar lógica entre módulos en lugar de mover a `utils`
- `#[allow(...)]` sin comentario explicando por qué
- `which` hardcodeado en lugar de `#[cfg(unix)]`
