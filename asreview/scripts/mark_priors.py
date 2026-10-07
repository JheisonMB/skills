#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Mark automatic priors (seeds) in ASReview CSV based on criteria.

Strategies:
  - top_n:     Top N records by a column (e.g., Cites, Year)
  - random:    Random N records
  - manual:    Mark specific record_ids

Usage:
  python mark_priors.py input.csv -s top_n:5:Cites -o output_priors.csv
  python mark_priors.py input.csv -s random:10 -o output_priors.csv
  python mark_priors.py input.csv -s manual:rec_001,rec_002 -o output_priors.csv
"""

import argparse
import csv
import sys
import random
from pathlib import Path


def parse_strategy(strategy_str):
    """Parse strategy string: top_n:N:COLUMN or random:N or manual:ID1,ID2,..."""
    parts = strategy_str.split(':')
    if not parts:
        raise ValueError("Invalid strategy format")

    strategy_type = parts[0].lower()
    if strategy_type == 'top_n':
        if len(parts) < 3:
            raise ValueError("top_n requires: top_n:N:COLUMN (e.g., top_n:5:Cites)")
        return ('top_n', int(parts[1]), parts[2])
    elif strategy_type == 'random':
        if len(parts) < 2:
            raise ValueError("random requires: random:N (e.g., random:5)")
        return ('random', int(parts[1]))
    elif strategy_type == 'manual':
        if len(parts) < 2:
            raise ValueError("manual requires: manual:ID1,ID2,... (e.g., manual:rec_001,rec_002)")
        ids = parts[1].split(',')
        return ('manual', [rid.strip() for rid in ids])
    else:
        raise ValueError(f"Unknown strategy: {strategy_type}")


def mark_priors(infile, outfile, strategy, seed=None):
    """Mark priors in CSV and write to outfile."""
    with open(infile, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames or []
        rows = list(reader)

    if not fieldnames:
        raise ValueError("No header found in CSV")

    # Ensure label column exists
    if 'label' not in fieldnames:
        fieldnames = list(fieldnames) + ['label']

    # Determine which rows to mark as priors
    prior_indices = set()
    strategy_type = strategy[0]

    if strategy_type == 'top_n':
        n, col = strategy[1], strategy[2]
        if col not in [f.lower() for f in fieldnames]:
            print(f"WARNING: column '{col}' not found, using top {n} by row order", file=sys.stderr)
            prior_indices = set(range(min(n, len(rows))))
        else:
            # Find actual column name (case-insensitive)
            col_actual = next((f for f in fieldnames if f.lower() == col.lower()), None)
            if col_actual:
                def parse_val(x):
                    try:
                        return int(str(x).replace(',', ''))
                    except:
                        try:
                            return int(float(x))
                        except:
                            return 0
                idxs = sorted(range(len(rows)), key=lambda i: parse_val(rows[i].get(col_actual, '0')), reverse=True)
                prior_indices = set(idxs[:n])

    elif strategy_type == 'random':
        n = strategy[1]
        if seed is not None:
            random.seed(seed)
        prior_indices = set(random.sample(range(len(rows)), min(n, len(rows))))

    elif strategy_type == 'manual':
        ids = strategy[1]
        prior_indices = {i for i, row in enumerate(rows) if row.get('record_id', '') in ids}

    # Mark priors
    for i, row in enumerate(rows):
        if 'label' not in row:
            row['label'] = ''
        if i in prior_indices:
            row['label'] = '1'
        elif not row['label']:
            row['label'] = '0'

    # Write output
    with open(outfile, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    return len(prior_indices)


def main():
    p = argparse.ArgumentParser(description="Mark priors (seeds) in ASReview CSV")
    p.add_argument("infile", help="Input ASReview CSV")
    p.add_argument("-s", "--strategy", required=True, 
                   help="Strategy: top_n:N:COLUMN | random:N | manual:ID1,ID2,...")
    p.add_argument("-o", "--out", default=None, help="Output CSV (default: <infile>_priors.csv)")
    p.add_argument("--seed", type=int, default=None, help="Random seed for reproducibility")
    p.add_argument("--quiet", action='store_true', help="Suppress output messages")
    args = p.parse_args()

    if not Path(args.infile).is_file():
        print(f"ERROR: input file not found: {args.infile}", file=sys.stderr)
        sys.exit(2)

    try:
        strategy = parse_strategy(args.strategy)
    except ValueError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    outfile = args.out or Path(args.infile).stem + "_priors.csv"

    try:
        n_marked = mark_priors(args.infile, outfile, strategy, seed=args.seed)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    if not args.quiet:
        print(f"✓ Marked {n_marked} priors (label=1) in: {outfile}")
        print(f"  Strategy: {args.strategy}")
        if args.seed is not None:
            print(f"  Seed: {args.seed}")


if __name__ == '__main__':
    main()
