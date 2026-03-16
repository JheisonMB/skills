---
name: webflux-test-reviewer
description: >
  Evaluador automático de pruebas técnicas de WebFlux para múltiples candidatos. Lee el enunciado, analiza el código de cada candidato, y genera un EVALUATION.md con criterios técnicos, preguntas para entrevista, y conclusión.

  Use this skill whenever the user:
  - Wants to evaluate, review, or grade technical assessments or coding tests
  - Has a project with a statement/ folder and candidate directories containing cloned repos
  - Mentions "evaluar prueba", "revisar prueba técnica", "review candidates", "evaluar candidatos", "prueba técnica", "technical assessment"
  - Asks to compare or assess multiple candidates' code submissions
  - Wants to generate interview questions based on code review findings

  Make sure to use this skill even if the user just says something like "revisa las pruebas", "evalúa los candidatos", or "review the tests" — if there's a statement/ directory and candidate folders, this skill applies.

  NOT for: general code reviews of a single project, non-assessment contexts, reviewing your own code.
license: MIT
metadata:
  author: jheison.martinez
  version: "1.0"
  framework: Spring WebFlux
  language: Java
  category: technical-assessment
  last_updated: "2026-03-16"
---

# WebFlux Test Reviewer

Evaluate WebFlux technical assessments from multiple candidates. Read the problem statement, analyze each candidate's code, and produce a structured evaluation report.

## Project Structure

The assessment project must follow this layout:

```
project-root/
├── statement/
│   └── *.md                    # The technical assessment problem statement
├── candidate-name-1/
│   ├── (cloned repo contents)
│   └── EVALUATION.md           # ← You generate this
├── candidate-name-2/
│   ├── (cloned repo contents)
│   └── EVALUATION.md           # ← You generate this
└── ...
```

Every directory at the root that is NOT `statement/` is a candidate. Extract the candidate's display name from the directory name (e.g., `jonathan-camano` → `Jonathan Camano`).

## Execution Flow

### 1. Read the Statement

Read all markdown files in `statement/`. This is your baseline — everything the candidate delivers gets contrasted against what was actually requested. Understanding the statement deeply is critical because it lets you catch candidates who missed requirements, over-engineered, or solved a different problem.

### 2. Evaluate All Candidates

Process all candidates automatically. If sub-agents are available, use them to evaluate candidates in parallel — each candidate is independent so this is safe. Otherwise, evaluate sequentially.

For each candidate:

**Explore the codebase.** Read the project structure, source files, configuration, and infrastructure files. Get a complete picture before judging anything.

**Check git history.** Run `git log --oneline` and `git branch -a` inside the candidate's directory. This reveals commit discipline, branch strategy, and work progression.

**Apply evaluation criteria.** Evaluate each criterion from [references/EVALUATION_CRITERIA.md](references/EVALUATION_CRITERIA.md). The criteria cover: Readme, Git, Webflux, Tests, Architecture, Clean Code, Exception Handling, IaC, Dockerfile, and Docker-compose. Each evaluation is free-text — describe what you found, not just "yes/no".

**Contrast against the statement.** For each criterion, consider whether the candidate fulfilled what was asked. If the statement required a CRUD API and the candidate built something else, that matters.

**Detect AI misuse.** Look for obvious AI-generated comments ("si quieres te puedo dar ideas..."), style inconsistencies across the codebase, and suspicious patterns like technically perfect code that shows no understanding of the business context. AI usage isn't inherently bad — what matters is whether the candidate understands what was generated. Note findings and turn them into interview questions.

**Flag exposed secrets.** If you find hardcoded credentials, API keys, or passwords, mention it in the relevant criterion. This isn't a formal criterion but it's worth noting.

**Generate interview questions.** Based on inconsistencies, questionable decisions, missing justifications, or interesting technical choices you found, generate questions to probe the candidate's understanding. No limit — generate as many as the code warrants.

**Write the conclusion.** A free-text overall assessment. Be direct and honest.

### 3. Generate EVALUATION.md

Write the report in each candidate's directory using this format:

```markdown
# [Candidate Name]

## BACK:
• Readme: [free-text evaluation]
• GIT: [free-text evaluation]
• Webflux: [free-text evaluation]
• Test Unitarios: [free-text evaluation]
• Arquitectura: [free-text evaluation]
• Clean Code: [free-text evaluation]
• Manejo de Excepciones: [free-text evaluation]
• IaC: [free-text evaluation]
• DockerFile: [free-text evaluation]
• Docker-compose: [free-text evaluation]

## Preguntas:
• [question based on code findings]
• [question based on code findings]
• ...

## Conclusión:
[free-text overall assessment]
```

Write the report in the **same language as the statement**. Spanish statement → Spanish report. English statement → English report.

### 4. WebFlux Technical Reference

When evaluating reactive code quality, reference the **webflux-reactive-patterns** skill if available. Key things to verify:
- `flatMap()` for async operations vs `map()` for sync transformations
- No blocking calls (`block()`, `Thread.sleep()`, blocking I/O)
- Lazy error handling with `Mono.defer(() -> Mono.error(...))`
- Parallel operations with `Mono.zip()` where applicable
- `switchIfEmpty()` for empty stream handling
- No imperative constructs (`if/else`, `throw`) inside reactive chains

## Evaluation Criteria Reference

For detailed criteria with examples of good and bad evaluations, read [references/EVALUATION_CRITERIA.md](references/EVALUATION_CRITERIA.md). Consult it when you need guidance on what specifically to look for in each criterion.

## Setup Script

To quickly create the candidate directory structure from GitHub URLs, run [scripts/setup_candidates.sh](scripts/setup_candidates.sh):

```bash
./scripts/setup_candidates.sh https://github.com/user1/repo https://github.com/user2/repo
```

This creates a directory per GitHub user and clones their repo inside it. After running, add a `statement/` directory with the assessment markdown.

## Report Template

The exact template with placeholders is at [assets/EVALUATION_TEMPLATE.md](assets/EVALUATION_TEMPLATE.md).
