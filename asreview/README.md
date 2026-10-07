# ASReview Skill

Active learning framework for rapid screening in systematic reviews. Includes integration with **Harzing Publish or Perish** for bibliographic data conversion.

## Overview

ASReview automates literature screening using machine learning and active learning. This skill provides comprehensive guidance for:

- Running AL simulations and benchmarks
- Manual interactive screening (GUI-based)
- Converting Harzing Publish or Perish exports to ASReview format
- Classifier/feature extractor selection
- Metrics extraction and evaluation

## Features

- **Simulation Mode**: Benchmark AL performance on fully labeled datasets
- **Interactive Review**: Manual screening with AL feedback (asreview lab)
- **Harzing Integration**: Auto-convert PoPCites.csv (Publish or Perish) to ASReview format
- **Multiple Algorithms**: NB, SVM, RF, LR classifiers; TF-IDF, Word2Vec, BERT extractors
- **Reproducibility**: Seed-based randomization for consistent results
- **Metrics Export**: Extract precision@N, recall@N, ranking from .asreview projects

## Installation

```bash
pip install asreview
```

## Quick Start

```bash
# Convert Harzing export
python scripts/convert_harzing_csv.py PoPCites.csv -o data_asreview.csv

# Mark top 5 priors
python scripts/mark_priors.py data_asreview.csv -s top_n:5:Cites -o data_priors.csv

# Run simulation
asreview simulate data_priors.csv --n-prior-included 5 --n-stop 100 -o sim.asreview --seed 1

# Extract metrics
python scripts/export_metrics.py sim.asreview -o metrics.json
```

## Usage

Activate this skill when:
- Conducting systematic reviews with large datasets
- Automating literature screening
- Evaluating active learning performance
- Converting Harzing Publish or Perish exports
- Running benchmarks on SYNERGY datasets

## Skill Structure

```
asreview/
├── SKILL.md                      # Main documentation
├── README.md                     # This file
├── CHANGELOG.md                  # Version history
├── scripts/                      # Utility scripts
│   ├── convert_harzing_csv.py   # Harzing → ASReview CSV
│   ├── export_metrics.py        # Extract metrics from .asreview
│   ├── mark_priors.py           # Auto-mark priors (seeds)
│   └── README.md                # Scripts documentation
├── references/
│   ├── EXAMPLES.md              # Practical workflow examples
│   ├── USAGE_GUIDELINES.md      # Best practices
│   └── SYNERGY_DATASETS.md      # Benchmark datasets
└── assets/
    └── example_dataset.csv       # Sample for testing
```

## Key Concepts

- **Prior**: Seeds (included/excluded records) to bootstrap active learning
- **AL Cycle**: Train model → Query uncertain records → Label → Retrain
- **Feature Extractor**: Converts text (title/abstract) to vectors (TF-IDF, Word2Vec, BERT)
- **Classifier**: Predicts label (0/1) and uncertainty (NB, SVM, RF, LR)
- **Querier**: Selects next record to label (max uncertainty, max random, random)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `ValueError: must have included records` | Mark at least 1 prior as included (label=1) or use `--n-prior-included 0` |
| Conversion script fails | Ensure CSV is UTF-8; use `--quiet` flag to suppress verbose output |
| `ModuleNotFoundError: _sqlite3` | Install libsqlite3-dev, reinstall Python |

## Resources

- [ASReview](https://asreview.nl/) — Official site
- [Harzing Publish or Perish](https://harzing.com/resources/publish-or-perish) — Bibliographic tool
- [SYNERGY Datasets](https://github.com/asreview/synergy-datasets) — Benchmark collection
- [Docs](references/EXAMPLES.md) — Practical examples and workflows

## Version

**v2.1** (2026-04-06) — Active learning screening with Harzing integration
