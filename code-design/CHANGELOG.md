# Changelog - Code Design Skill

## Version 1.0 (2026-04-06)

### Initial Release

Production-grade coding behavior skill for AI agents, language-agnostic.

#### Features
- **Zero uncertainty before coding** — resolve all ambiguity before writing code
- **Respect existing patterns** — scan codebase for conventions and follow them
- **Prioritized design principles** — SoC > DRY > YAGNI > KISS > Fail Fast > SOLID > LoD with explicit conflict resolution
- **Explicit naming** — no acronyms, follow language style guides, readable names
- **Fail fast with guard clauses** — negative validations first, reduce nesting
- **Code size limits** — methods ≤30 lines, nesting ≤3 levels (conditionals and reactive chains)
- **Formatting** — always use project formatter (cargo fmt, go fmt, prettier, etc.)
- **Error handling** — guard clauses + explicit error types when language supports them
- **Testing posture** — tests after functionality is stable, unit tests first
- **Atomic commits** — conventional commits, one logical change, single phrase in English
- **Tech debt handling** — notify user, leave TODO, ask before refactoring
- **Anti-pattern resolution** — ask user before following or breaking established anti-patterns
- **Pattern decision tree** — three trees (creational, structural, behavioral) with when NOT to use
- **Code quality checklist** — 11-item verification before presenting any code change
- **Composition with mindful-precision** — explicit complementary relationship

#### Files
- `SKILL.md` — Core skill with principles, decision trees, and checklist
- `README.md` — Skill documentation with radar diagram
- `CHANGELOG.md` — Version history
- `references/design-patterns.md` — Full catalog of 23 GoF patterns

#### Design Decisions
- **Language-agnostic** — principles apply to any language/framework
- **Prioritized principles** — explicit priority order resolves conflicts between YAGNI vs OCP, KISS vs DIP
- **Complements mindful-precision** — mindful handles behavior, developer handles code quality
- **Decision trees over rules** — guide the agent through questions, not memorization
- **"Respect existing patterns" with escape hatch** — follow conventions but flag violations with TODOs

#### Sources
- Design patterns catalog based on [software-patterns-guide](https://jheisonmb.github.io/software-patterns-guide/)
