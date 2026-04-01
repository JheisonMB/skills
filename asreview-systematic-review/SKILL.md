---
name: asreview-systematic-review
description: >
  Guía experta para usar ASReview en revisiones sistemáticas y aprendizaje activo.
  Activa cuando el usuario trabaje con revisión sistemática, screening de literatura,
  aprendizaje activo, simulaciones de revisión, datasets SYNERGY, o comandos como
  'asreview simulate'. También activa cuando describa filtrado automatizado de
  literatura científica sin mencionar ASReview explícitamente.
license: MIT
metadata:
  author: jheison.martinez
  version: "1.1"
  framework: ASReview
  language: Python
  category: systematic-review-automation
  last_updated: "2026-03-31"
---

# ASReview Systematic Review Skill

ASReview automatiza el screening de títulos y abstracts en revisiones sistemáticas usando aprendizaje activo. Requiere ASReview v2+.

## Instalación

```bash
pip install asreview
asreview --version  # verificar
```

## Flujo típico

```bash
# 1. Simular con dataset propio
asreview simulate dataset.csv -o result.asreview --seed 42

# 2. Simular con dataset SYNERGY (benchmarking)
asreview simulate synergy:van_de_schoot_2018 -o result.asreview --seed 42

# 3. Revisión manual con GUI
asreview lab
```

## Opciones clave

| Opción | Valores | Default |
|--------|---------|---------|
| `-c` classifier | `nb`, `svm`, `rf`, `lr` | `nb` |
| `-e` feature-extractor | `tfidf`, `word2vec`, `bert` | `tfidf` |
| `-q` querier | `max`, `max_random`, `random` | `max` |
| `--seed` | cualquier entero | — |
| `--n-prior-included` | entero | 0 |
| `--n-prior-excluded` | entero | 0 |
| `--n-stop` | entero | sin límite |

## Formato del dataset

CSV con columnas obligatorias: `title`, `abstract`, `label` (0=excluido, 1=incluido). Encoding UTF-8.

## Cuándo usar cada clasificador

- `nb` + `tfidf` — punto de partida, rápido, bueno para la mayoría de casos
- `svm` + `tfidf` — mejor precisión en datasets medianos
- `bert` — solo si el dominio es muy especializado y hay recursos de cómputo

## Si la simulación falla

1. Verificar columnas del CSV: `head -n 3 dataset.csv`
2. Verificar encoding: el archivo debe ser UTF-8
3. Probar con dataset SYNERGY para aislar si el problema es el dataset
4. Reducir con `--n-stop 50` para prueba rápida

## Referencias

- Ejemplos detallados: `references/EXAMPLES.md`
- Datasets SYNERGY disponibles: `references/SYNERGY_DATASETS.md`
- Guías de uso avanzado: `references/USAGE_GUIDELINES.md`
