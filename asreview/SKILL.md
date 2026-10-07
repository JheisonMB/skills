---
name: asreview
description: >
  Active learning framework for rapid screening in systematic reviews.
  Triggered on ASReview workflows: screening, simulation, benchmark, 
  automated literature filtering. Also handles Harzing Publish or Perish 
  exports (PoPCites CSV) conversion to ASReview-compatible format.
license: MIT
metadata:
  author: jheison.martinez
  version: "2.1"
  framework: ASReview
  language: Python
  integrations: [Harzing Publish or Perish]
  category: systematic-review-automation
  last_updated: "2026-04-06"
---

# ASReview — Active Learning for Literature Screening

ASReview automates title/abstract screening in systematic reviews using active learning (AL). Requires ASReview v2+.

## Quick Start

```bash
# Install
pip install asreview

# Simulate (benchmark mode) on your dataset
asreview simulate dataset.csv -o result.asreview --seed 42 --n-prior-included 2

# Manual review (GUI)
asreview lab
```

## Converting Harzing Publish or Perish Exports

Harzing's **Publish or Perish** tool exports bibliographic data as CSV (e.g., `PoPCites.csv`). This format must be converted to ASReview's standard before screening.

### CSV Conversion

**Input (Harzing Publish or Perish):**
```
Title,Abstract,DOI,Authors,...
"My Title","Abstract text...","10.xxxx/yyyy",...
```

**Output (ASReview-ready):**
```csv
record_id,title,abstract,label,doi
10.xxxx/yyyy,"My Title","Abstract text...",
rec_000001,"Another Title","More abstract...",
```

**Conversion script** (handles BOM, missing DOIs, column mapping):
```bash
# Default: PoPCites.csv → PoPCites_asreview.csv
python convert_popcites_to_asreview.py

# Custom input/output
python convert_popcites_to_asreview.py input.csv -o output_asreview.csv
```

**Key features:**
- Auto-detects Title, Abstract, DOI columns (case-insensitive, fuzzy matching)
- Generates `rec_XXXXXX` IDs for records without DOI
- Normalizes encoding (UTF-8 BOM support)
- Outputs: record_id, title, abstract, label (empty), doi

---

## Core Commands

| Command | Purpose |
|---------|---------|
| `asreview simulate` | Benchmark AL performance on fully labeled dataset |
| `asreview lab` | Interactive GUI for manual screening + AL feedback |
| `asreview export` | Extract metrics, rankings from .asreview projects |

## Key Flags

| Flag | Type | Default | Notes |
|------|------|---------|-------|
| `-c` `--classifier` | `nb`, `svm`, `rf`, `lr` | `nb` | Naive Bayes fast, SVM accurate |
| `-e` `--feature-extractor` | `tfidf`, `word2vec`, `bert` | `tfidf` | TFIDF recommended; BERT needs GPU |
| `-q` `--querier` | `max`, `max_random`, `random` | `max` | Max uncertainty; max_random adds noise |
| `-b` `--balancer` | `undersample`, `oversample` | auto | Handle imbalanced labels |
| `--n-prior-included` | int | 0 | Seeds: true positives to start with |
| `--n-prior-excluded` | int | 0 | Seeds: true negatives to start with |
| `--n-stop` | int | — | Stop after N labeled (e.g. 50 labels) |
| `--n-query` | int | 1 | Labels to assign per iteration |
| `--seed` | int | — | Reproducibility seed |

## CSV Format (Required)

```csv
record_id,title,abstract,label
rec_1,"My Title","My abstract text...",1
rec_2,"Another Title","More abstract...",0
```

- `record_id`: unique identifier (e.g. DOI or auto-generated)
- `title`, `abstract`: AL input (required for learning)
- `label`: 0 (excluded) or 1 (included); empty if unlabeled (for active review)

## Typical Workflows

### 1. Benchmark: Simulate AL on fully labeled dataset

```bash
# All records must have label 0 or 1
asreview simulate my_data.csv \
  --n-prior-included 2 \
  --n-stop 100 \
  --seed 1 \
  -o my_sim.asreview
```

Output: .asreview (ZIP) with data/, results.db (metrics), feature_matrices/.

### 2. Manual Review: Interactive screening with AL feedback

```bash
# Create empty .asreview project (GUI)
asreview lab

# Or import dataset and screen:
asreview lab --dataset my_data.csv
```

### 3. Evaluate: Extract metrics from results.db

```bash
# Extract ranking, precision@N, recall@N
asreview metrics my_sim.asreview --export-metrics metrics.csv
```

### 4. Convert Harzing Export → Screen with ASReview

```bash
# 1. Export from Publish or Perish as CSV (PoPCites.csv)
# 2. Convert
python convert_popcites_to_asreview.py PoPCites.csv -o PoPCites_asreview.csv

# 3. Label a subset manually or mark priors, then screen
asreview simulate PoPCites_asreview.csv --n-prior-included 5 --n-stop 100 -o PoPCites_sim.asreview --seed 1
```

## Classifier Recipes

| Scenario | Config |
|----------|--------|
| Fast prototyping | `--classifier nb --feature-extractor tfidf` |
| High precision (small dataset) | `--classifier svm --feature-extractor tfidf` |
| Imbalanced labels (many negatives) | `--classifier rf --balancer undersample` |
| Domain-specific (rare terms) | `--classifier lr --feature-extractor bert` (needs GPU) |

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `ValueError: must have included records` | No labels=1 in CSV | Mark at least 1 prior as included, or use `--n-prior-included 0` |
| `ModuleNotFoundError: _sqlite3` | Python compiled without sqlite | Install libsqlite3-dev, reinstall pyenv |
| `Can't compute loss and gain...` | All records same class | Add mixed labels (0 and 1) |
| `TypeError: NoneType + int` | Empty label cells | Fill all label cells with 0 or 1 |
| Conversion script not finding CSV | File in different directory | Pass full path or place CSV in same dir as script |

## Tips

- **Reproducibility**: Always use `--seed N` for consistent AL trajectories
- **Fast testing**: Use `--n-stop 50` to limit iterations
- **Active learning gain**: Compare `--n-prior-included 2 --n-stop 100` (AL) vs random baseline
- **Feature extraction**: Start with `tfidf`; switch to `word2vec`/`bert` only if accuracy plateaus
- **Harzing exports**: Use Publish or Perish's "Export to CSV" to get standard format; script handles column name variations

## References

- ASReview: [asreview.nl](https://asreview.nl/) | Docs: [GitHub](https://github.com/asreview/asreview)
- Harzing Publish or Perish: [harzing.com/resources/publish-or-perish](https://harzing.com/resources/publish-or-perish)
- SYNERGY benchmarks: `synergy:van_de_schoot_2018`, `synergy:cohen_2006`, etc.
- Skill references: `references/EXAMPLES.md`, `references/SYNERGY_DATASETS.md`, `references/USAGE_GUIDELINES.md`
