#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extract metrics from ASReview .asreview project (results.db).

Outputs: precision, recall, rank of relevant records, and summary stats.

Usage:
  python export_metrics.py my_sim.asreview -o metrics.json
  python export_metrics.py my_sim.asreview --csv metrics.csv
"""

import argparse
import sqlite3
import zipfile
import json
import csv
import sys
import os
from pathlib import Path


def extract_results_db(asreview_path):
    """Extract results.db from .asreview ZIP."""
    tmp_db = Path(f"/tmp/{os.path.basename(asreview_path)}_results.db")
    try:
        with zipfile.ZipFile(asreview_path) as zf:
            if 'results.db' not in zf.namelist():
                raise FileNotFoundError("results.db not found in .asreview")
            with zf.open('results.db') as rf:
                tmp_db.write_bytes(rf.read())
        return str(tmp_db)
    except Exception as e:
        print(f"ERROR: failed to extract results.db: {e}", file=sys.stderr)
        sys.exit(1)


def compute_metrics(db_path):
    """Compute precision, recall, and ranking from results.db."""
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Total results labeled
    cur.execute("SELECT COUNT(*) FROM results")
    total_labeled = cur.fetchone()[0]

    # Included records found
    cur.execute("SELECT COUNT(*) FROM results WHERE label = 1")
    included_found = cur.fetchone()[0]

    # Ground truth included (from record table)
    cur.execute("SELECT COUNT(*) FROM record WHERE included = 1")
    total_included = cur.fetchone()[0]

    # Compute metrics
    recall = included_found / total_included if total_included > 0 else None
    precision = included_found / total_labeled if total_labeled > 0 else None

    # Get ranking order of included records
    cur.execute("""
        SELECT r.record_id, rec.title, r.rowid as review_order
        FROM results r
        LEFT JOIN record rec ON rec.dataset_row = r.record_id
        WHERE r.label = 1
        ORDER BY r.rowid
    """)
    included_order = cur.fetchall()

    conn.close()

    return {
        "total_labeled": total_labeled,
        "total_included_in_dataset": total_included,
        "included_found": included_found,
        "precision": round(precision, 4) if precision is not None else None,
        "recall": round(recall, 4) if recall is not None else None,
        "included_records": [
            {"rank": i+1, "record_id": r[0], "title": r[1][:80] + "..." if len(r[1]) > 80 else r[1]}
            for i, r in enumerate(included_order)
        ]
    }


def main():
    p = argparse.ArgumentParser(description="Extract metrics from ASReview .asreview project")
    p.add_argument("asreview", help="Path to .asreview project file")
    p.add_argument("-o", "--out", default="metrics.json", help="Output file (default: metrics.json)")
    p.add_argument("--csv", action='store_true', help="Output as CSV instead of JSON")
    p.add_argument("--quiet", action='store_true', help="Suppress output messages")
    args = p.parse_args()

    if not os.path.isfile(args.asreview):
        print(f"ERROR: .asreview file not found: {args.asreview}", file=sys.stderr)
        sys.exit(2)

    db_path = extract_results_db(args.asreview)
    metrics = compute_metrics(db_path)

    if args.csv:
        with open(args.out, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=["metric", "value"])
            writer.writeheader()
            for k, v in metrics.items():
                if k != "included_records":
                    writer.writerow({"metric": k, "value": v})
            writer.writerow({"metric": "included_records_count", "value": len(metrics["included_records"])})
    else:
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(metrics, f, indent=2, ensure_ascii=False)

    if not args.quiet:
        print(f"✓ Metrics extracted to: {args.out}")
        print(f"  Precision: {metrics['precision']}")
        print(f"  Recall: {metrics['recall']}")
        print(f"  Included found: {metrics['included_found']}/{metrics['total_included_in_dataset']}")

    # Clean up
    try:
        os.remove(db_path)
    except:
        pass


if __name__ == '__main__':
    main()
