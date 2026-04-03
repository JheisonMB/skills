# texforge skill

Agent skill for the [texforge](https://github.com/JheisonMB/texforge) CLI — a self-contained LaTeX to PDF compiler with no external dependencies.

## What it does

Teaches the agent how to use the texforge CLI to:

- Create LaTeX projects from templates (`texforge new`) or interactively (`texforge init`)
- Migrate existing LaTeX projects (`texforge init` — auto-detected)
- Compile `.tex` files to PDF (`texforge build`)
- Watch for changes and rebuild automatically (`texforge build --watch`)
- Format and lint documents (`texforge fmt`, `texforge check`)
- Manage templates (`texforge template`)

## Resources

- **CLI**: [github.com/JheisonMB/texforge](https://github.com/JheisonMB/texforge)
- **Templates**: [github.com/JheisonMB/texforge-templates](https://github.com/JheisonMB/texforge-templates)

## Install skill

```bash
npx skills add https://github.com/jheisonmb/skills --skill texforge
```
