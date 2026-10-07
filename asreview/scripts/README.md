# ASReview Skill — Scripts

Utility scripts for ASReview workflow automation.

## Scripts

### convert_harzing_csv.py
Convert Harzing Publish or Perish exports to ASReview format.

```bash
python convert_harzing_csv.py PoPCites.csv -o data_asreview.csv
python convert_harzing_csv.py input.csv --quiet  # suppress output
```

**Features:**
- Auto-detect Title, Abstract, DOI columns
- Generate record_id from DOI or auto-generate rec_000001, rec_000002, ...
- Handle UTF-8 BOM and missing fields
- Output: record_id, title, abstract, label (empty), doi

### export_metrics.py
Extract precision, recall, and record ranking from .asreview projects.

```bash
python export_metrics.py my_sim.asreview -o metrics.json
python export_metrics.py my_sim.asreview --csv metrics.csv
python export_metrics.py my_sim.asreview --quiet
```

**Output (JSON):**
```json
{
  "total_labeled": 50,
  "total_included_in_dataset": 10,
  "included_found": 10,
  "precision": 0.2,
  "recall": 1.0,
  "included_records": [
    {"rank": 1, "record_id": "rec_001", "title": "Title 1..."},
    ...
  ]
}
```

### mark_priors.py
Automatically mark priors (seeds) in ASReview CSVs using various strategies.

```bash
# Mark top 5 by citation count
python mark_priors.py input.csv -s top_n:5:Cites -o priors.csv

# Mark 10 random records (reproducible)
python mark_priors.py input.csv -s random:10 --seed 42 -o priors.csv

# Mark specific record IDs manually
python mark_priors.py input.csv -s manual:rec_001,rec_005,10.xxxx/yyyy -o priors.csv
```

**Strategies:**
- `top_n:N:COLUMN` — Top N by numeric column (e.g., Cites, Year)
- `random:N` — N random records
- `manual:ID1,ID2,...` — Specific record_ids

**Output:** CSV with label column (1=included prior, 0=excluded prior)

## Example Workflow

```bash
# 1. Convert Harzing export
python convert_harzing_csv.py PoPCites.csv -o my_data_asreview.csv

# 2. Mark top 5 papers as priors
python mark_priors.py my_data_asreview.csv -s top_n:5:Cites -o my_data_priors.csv

# 3. Run ASReview simulation
asreview simulate my_data_priors.csv --n-prior-included 5 --n-stop 100 -o sim.asreview --seed 1

# 4. Extract metrics
python export_metrics.py sim.asreview -o metrics.json

# 5. View results
cat metrics.json
```

## Requirements

- Python 3.7+
- pandas (optional; falls back to csv module if not installed)
- asreview (for simulate/export commands)

## Notes

- All scripts use UTF-8 encoding and handle missing fields gracefully
- Use `--quiet` flag to suppress informational output
- Scripts are idempotent (safe to re-run)
