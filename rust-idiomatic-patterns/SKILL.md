---
name: rust-idiomatic-patterns
description: >
  Idiomatic Rust guide for writing, reviewing, and refactoring clean, safe, and efficient code. Focuses on ownership/borrowing, Result/Option, iterators, APIs, modules, DRY, SoC, fail-fast, and clippy.

  Activate when working with Rust, cargo, ownership, borrow, lifetimes, Result, Option, traits, enums, structs, iterators, anyhow, thiserror, clippy, or a Rust review/refactor.
  Do not use for languages other than Rust.
license: MIT
metadata:
  author: jheison.martinez
  version: "1.2"
  language: Rust
  category: language-patterns
  last_updated: "2026-05-05"
---

# Rust Idiomatic Patterns

Actionable rules extracted from real experience. No theory - only decisions.

---

## Refactor Philosophy: Functional Checkpoint Goals 🔵 UPDATED

Refactoring is driven by **Logical Checkpoints**. Each commit must represent a complete, functional milestone in the evolution of the codebase.

1.  **Define the Checkpoint**: Identify a logical functional unit (e.g., "Extract Domain Logic from main.rs to domain/ module").
2.  **Execute Goal**: Modify all necessary files to achieve the goal. This often involves creating new files and updating multiple callers simultaneously.
3.  **Functional Integrity**: Ensure the code is functionally correct. The project MUST compile and pass `cargo clippy --all-targets -- -D warnings` and all relevant tests.
4.  **Atomic Milestone Commit**: Make a single commit for the entire logical change. Do not split a single functional goal into multiple broken commits.
5.  **Re-evaluate**: Once the checkpoint is reached and verified, define the next logical goal.

If a goal becomes too complex (taking too long to reach a passing state), revert and break it into two smaller **functional** checkpoints.

---

## Ownership & Borrowing

**Golden rule: never call `.clone()` unless the compiler forces it.**

| Situation | Use |
|---|---|
| Parameter you only read | `&T`, `&str`, `&[T]` |
| Parameter you need to own | `T`, `String`, `Vec<T>` |
| Return value you produce | `String`, `Vec<T>` |
| Return value you read from `self` | `&T`, `&str` |
| Ambiguous ownership | `Cow<', T>` |
| Type <= 24 bytes + Copy | pass by value |

If you clone, ask whether the design is wrong.

---

## Errors

```rust
// Library - typed enum with thiserror
#[derive(thiserror::Error, Debug)]
enum AppError {
    #[error("not found: {0}")]
    NotFound(String),
}

// Binary/CLI - anyhow with context
fn execute() -> anyhow::Result<()> {
    do_thing().context("Failed to do thing")?;
    Ok(())
}
```

- Use `unwrap()` / `expect()` only in tests
- Prefer `?` over `match` for propagation
- Use `.with_context(|| format!(...))` when the message needs dynamic data
- **Fail Fast**: validate inputs up front, before doing expensive work

```rust
// ✅ Fail Fast - validate first
fn render_env(content: &str, pos: &str) -> Result<String> {
    if !["H", "t", "b", "h", "p"].contains(&pos) {
        anyhow::bail!("Invalid pos='{}' - valid: H, t, b, h, p", pos);
    }
    // expensive work later
    let png = render_to_png(content)?;
    ...
}
```

---

## Iterators

```rust
// ✅ chain directly
let total: u32 = items.iter()
    .filter(|x| x.active)
    .map(|x| x.value)
    .sum();

// ❌ unnecessary intermediate collect()
let filtered: Vec<_> = items.iter().filter(...).collect();
let total: u32 = filtered.iter().map(...).sum();
```

- Use `.iter()` for Copy types, `.into_iter()` when you need ownership
- `filter_map` > separate `filter` + `map`
- `.find(|p| p.exists())` > manual loop with `break`

---

## Structs & Enums

```rust
// let...else for fail-fast without nesting
let Some(value) = maybe_value else { return; };

// Prefer enums over bool flags when there are more than 2 states
enum Status { Active, Inactive, Pending }  // ✅
struct Item { is_active: bool }            // ❌

// Use Box<T> for large variants
enum Event {
    Small(u32),
    Large(Box<BigData>),  // avoids large_enum_variant warning
}
```

---

## Functions & SoC

One function = one responsibility. If the name needs "and" or "or", split it.

```rust
// ✅ separated - each function does one thing
fn locate_binary() -> Option<PathBuf> { ... }
fn install_binary(dest: &Path) -> Result<()> { ... }
fn find_or_install() -> Result<PathBuf> {
    if let Some(p) = locate_binary() { return Ok(p); }
    let dest = managed_path()?;
    install_binary(&dest)?;
    Ok(dest)
}

// ❌ mixed - find + install + report + decide
fn find_tectonic() -> Result<PathBuf> { ... }
```

---

## DRY - Unify with Generics and Closures

When two functions share the same skeleton with different logic in the middle:

```rust
// ❌ duplicated
fn detect_entry(root: &Path) -> Option<String> {
    for entry in WalkDir::new(root).max_depth(2) { ... }
}
fn detect_bib(root: &Path) -> Option<String> {
    for entry in WalkDir::new(root).max_depth(3) { ... }
}

// ✅ unified with a closure
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

## Visibility & Modules

- Use `pub(crate)` to expose items between internal modules without making them public API
- Move shared utilities to `utils/mod.rs` - do not duplicate them across modules
- If two modules have the same private function, it belongs in `utils`

```rust
// ❌ resolve_tex_path in linter/mod.rs AND resolve_tex in diagrams/mod.rs
// ✅ resolve_tex_path in utils/mod.rs, imported where needed
```

---

## cfg Without unreachable_code

```rust
// ✅ - without allow(unreachable_code)
#[cfg(unix)]
fn which_cmd() -> &'static str { "which" }
#[cfg(not(unix))]
fn which_cmd() -> &'static str { "where" }

// ✅ - for unsupported platforms
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
// Name: what_it_does_when_condition
#[test]
fn validate_name_returns_error_when_empty() { ... }

// One assert per test when possible
// tempfile::TempDir for filesystem tests
// Do not mock what you can test for real
#[test]
fn lint_detects_missing_includegraphics() {
    let dir = TempDir::new().unwrap();
    fs::write(dir.path().join("main.tex"), "\\includegraphics{missing.png}").unwrap();
    let errors = lint(dir.path(), "main.tex", None).unwrap();
    assert!(errors.iter().any(|e| e.message.contains("missing.png")));
}
```

---

## Clippy - Always Run

```bash
cargo clippy --all-targets -- -D warnings
cargo fmt --check
```

| Lint | Detects |
|---|---|
| `redundant_clone` | unnecessary `.clone()` |
| `needless_pass_by_value` | parameter that should be `&T` |
| `large_enum_variant` | variant that should be `Box<T>` |
| `manual_let_else` | `match` that should be `let...else` |
| `doc_markdown` | missing backticks in doc comments |

---

## Red Flags - Never in Production

- `unwrap()` outside tests
- `.clone()` in loops
- intermediate `collect()` without need
- function that does more than one thing
- duplicating logic across modules instead of moving it to `utils`
- `#[allow(...)]` without a comment explaining why
- hardcoded `which` instead of `#[cfg(unix)]`
