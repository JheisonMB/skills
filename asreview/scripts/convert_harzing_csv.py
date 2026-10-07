#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convert Harzing Publish or Perish CSV export to ASReview-compatible format.

Input: PoPCites.csv (Harzing export with Title, Abstract, DOI, etc.)
Output: ASReview CSV (record_id, title, abstract, label, doi)

Usage:
  python convert_harzing_csv.py input.csv -o output_asreview.csv
  python convert_harzing_csv.py --quiet input.csv  # suppress output
"""

import argparse
import csv
import os
import sys

try:
    import pandas as pd
except Exception:
    pd = None


def _find_col(columns, targets):
    """Find column by exact or fuzzy match (case-insensitive)."""
    if not columns:
        return None
    norm = {c.lower().strip(): c for c in columns}
    for t in targets:
        k = t.lower().strip()
        if k in norm:
            return norm[k]
    for c in columns:
        lc = c.lower()
        for t in targets:
            if t.lower() in lc:
                return c
    return None


def convert_with_pandas(infile, outfile):
    df = pd.read_csv(infile, encoding="utf-8-sig", low_memory=False)
    cols = list(df.columns)

    title_col = _find_col(cols, ["title", "titulo"]) or cols[0]
    abstract_col = _find_col(cols, ["abstract", "resumen", "summary"]) or None
    doi_col = _find_col(cols, ["doi"]) or None

    titles = df[title_col].astype(str).fillna("")
    abstracts = df[abstract_col].astype(str).fillna("") if abstract_col else pd.Series([""] * len(df))
    dois = df[doi_col].astype(str).fillna("") if doi_col else pd.Series([""] * len(df))

    out = pd.DataFrame({"title": titles, "abstract": abstracts, "doi": dois})

    out["record_id"] = out["doi"].where(out["doi"].astype(bool), None)
    missing_mask = out["record_id"].isna().to_numpy()
    gen_ids = [f"rec_{i:06d}" for i in range(len(out))]
    out.loc[missing_mask, "record_id"] = [gen_ids[i] for i, m in enumerate(missing_mask) if m]

    out["label"] = ""
    out = out[["record_id", "title", "abstract", "label", "doi"]]
    out.to_csv(outfile, index=False, encoding="utf-8")
    return len(out)


def convert_with_csv(infile, outfile):
    with open(infile, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        cols = reader.fieldnames or []
        title_col = _find_col(cols, ["title", "titulo"]) or (cols[0] if cols else None)
        abstract_col = _find_col(cols, ["abstract", "resumen", "summary"]) or None
        doi_col = _find_col(cols, ["doi"]) or None

        rows = []
        for i, row in enumerate(reader):
            title = (row.get(title_col) or "").strip() if title_col else ""
            abstract = (row.get(abstract_col) or "").strip() if abstract_col else ""
            doi = (row.get(doi_col) or "").strip() if doi_col else ""
            rows.append({"title": title, "abstract": abstract, "doi": doi})

    out_rows = []
    for idx, r in enumerate(rows):
        rid = r["doi"] if r["doi"] else f"rec_{idx:06d}"
        out_rows.append({
            "record_id": rid,
            "title": r["title"],
            "abstract": r["abstract"],
            "label": "",
            "doi": r["doi"],
        })

    with open(outfile, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["record_id", "title", "abstract", "label", "doi"])
        writer.writeheader()
        writer.writerows(out_rows)

    return len(out_rows)


def main():
    p = argparse.ArgumentParser(description="Convert Harzing Publish or Perish CSV to ASReview format")
    p.add_argument("infile", help="Path to Harzing CSV export (PoPCites.csv)")
    p.add_argument("-o", "--out", default=None, help="Output CSV path (default: <infile>_asreview.csv)")
    p.add_argument("--quiet", action='store_true', help="Suppress output messages")
    args = p.parse_args()

    if not os.path.isfile(args.infile):
        print(f"ERROR: input file not found: {args.infile}", file=sys.stderr)
        sys.exit(2)

    outfile = args.out or os.path.splitext(args.infile)[0] + "_asreview.csv"

    try:
        if pd:
            n = convert_with_pandas(args.infile, outfile)
        else:
            n = convert_with_csv(args.infile, outfile)
    except Exception as e:
        print(f"ERROR: conversion failed: {e}", file=sys.stderr)
        sys.exit(1)

    if not args.quiet:
        print(f"✓ Wrote {n} records to: {outfile}")
        print(f"  Columns: record_id, title, abstract, label, doi")
        print(f"  Ready for: asreview simulate {os.path.basename(outfile)} --n-prior-included 2 --n-stop 100")


if __name__ == '__main__':
    main()
