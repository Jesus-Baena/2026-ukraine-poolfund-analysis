#!/usr/bin/env python3
"""
Build the static data files served by the CBPF Grant Size Explorer.

Reads the CBPF OData "ProjectSummary" and "Cluster" entity sets, either from
an archive snapshot directory (gzipped OData JSON) or from two CSV exports,
and writes:

  public/data/cbpf_grants.json   one row per grant (allocation_year, fund,
                                 org_name, org_type, budget, cluster, source)
  public/data/cbpf_meta.json     year range, fund list, snapshot date, counts

The pipeline mirrors the Quarto report / Shiny v2 app exactly:

  * keep AllocationYear >= 2014 and Budget > 0 (nulls dropped)
  * OrganizationType -> short org_type label
  * primary cluster per project = Cluster row with the highest Percentage for
    that ChfProjectCode (globally unique; ChfId is NOT), shortened names,
    "Unknown" when no cluster row exists
  * source = AllocationSourceName ("Standard" / "Reserve")

Usage:

  python3 scripts/build_data.py --snapshot-dir /path/to/snap/2026-10-06 \
      --vintage 2026-10-06

  python3 scripts/build_data.py \
      --project-summary Raw-data/ProjectSummary_ALL_20260901_snapshot.csv \
      --cluster Raw-data/Cluster_ALL_20260901_snapshot.csv \
      --vintage 2026-09-01

Standard library only.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import gzip
import json
import os
import sys
from pathlib import Path
from typing import Any, Iterable

MIN_YEAR = 2014

ORG_TYPE_MAP = {
    "International NGO": "INGO",
    "National NGO": "NNGO",
    "UN Agency": "UN Agency",
    "Others": "Others",
    "Red Cross/Crescent": "Red Cross",
}
ORG_TYPE_FALLBACK = "Other (uncategorised)"

CLUSTER_SHORT = {
    "Water, Sanitation and Hygiene": "WASH",
    "Emergency Shelter and NFI": "Shelter & NFI",
    "Camp Coordination / Management": "Camp Coord./Mgmt",
    "Coordination and Support Services": "Coord. & Support",
    "Emergency Telecommunications": "Telecoms",
}
CLUSTER_UNKNOWN = "Unknown"


# --------------------------------------------------------------------------- #
# Input readers
# --------------------------------------------------------------------------- #

def read_odata_gz(path: Path) -> list[dict[str, Any]]:
    with gzip.open(path, "rt", encoding="utf-8") as fh:
        doc = json.load(fh)
    if isinstance(doc, dict) and "value" in doc:
        return list(doc["value"])
    if isinstance(doc, list):
        return doc
    raise ValueError(f"{path}: unexpected OData JSON shape")


def read_csv(path: Path) -> list[dict[str, Any]]:
    with open(path, newline="", encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))


def to_float(v: Any) -> float | None:
    if v is None:
        return None
    if isinstance(v, (int, float)):
        return float(v)
    s = str(v).strip()
    if s == "" or s.upper() in {"NA", "NULL", "NAN"}:
        return None
    try:
        return float(s)
    except ValueError:
        return None


def to_int(v: Any) -> int | None:
    f = to_float(v)
    return None if f is None else int(f)


def clean_str(v: Any) -> str:
    if v is None:
        return ""
    return str(v).strip()


# --------------------------------------------------------------------------- #
# Transform
# --------------------------------------------------------------------------- #

def primary_cluster_by_project(cluster_rows: Iterable[dict[str, Any]]) -> dict[str, str]:
    """ChfProjectCode -> shortened primary cluster (highest Percentage)."""
    best: dict[str, tuple[float, str]] = {}
    for r in cluster_rows:
        code = clean_str(r.get("ChfProjectCode"))
        if not code:
            continue
        name = clean_str(r.get("Cluster"))
        if not name:
            continue
        pct = to_float(r.get("Percentage"))
        pct = -1.0 if pct is None else pct
        cur = best.get(code)
        # strictly greater keeps the first row on ties (matches dplyr slice_max
        # with_ties=FALSE on the original ordering)
        if cur is None or pct > cur[0]:
            best[code] = (pct, name)
    return {code: CLUSTER_SHORT.get(name, name) for code, (_, name) in best.items()}


def build_grants(
    projects: Iterable[dict[str, Any]],
    cluster_map: dict[str, str],
) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for r in projects:
        year = to_int(r.get("AllocationYear"))
        budget = to_float(r.get("Budget"))
        if year is None or year < MIN_YEAR:
            continue
        if budget is None or budget <= 0:
            continue
        code = clean_str(r.get("ChfProjectCode"))
        org_type_raw = clean_str(r.get("OrganizationType"))
        out.append({
            "allocation_year": year,
            "fund": clean_str(r.get("PooledFundName")),
            "org_name": clean_str(r.get("OrganizationName")),
            "org_type": ORG_TYPE_MAP.get(org_type_raw, ORG_TYPE_FALLBACK),
            "budget": int(round(budget)),
            "cluster": cluster_map.get(code, CLUSTER_UNKNOWN),
            "source": clean_str(r.get("AllocationSourceName")) or "Unknown",
        })
    out.sort(key=lambda g: (g["allocation_year"], g["fund"], g["org_name"], g["budget"]))
    return out


def build_meta(grants: list[dict[str, Any]], vintage: str) -> dict[str, Any]:
    years = [g["allocation_year"] for g in grants]
    funds = sorted({g["fund"] for g in grants}, key=str.casefold)
    return {
        "year_min": min(years) if years else MIN_YEAR,
        "year_max": max(years) if years else MIN_YEAR,
        "funds": funds,
        "snapshot_date": vintage,
        "n_grants": len(grants),
        "n_funds": len(funds),
        "built_at": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat(),
    }


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #

def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    src = p.add_argument_group("input (choose one)")
    src.add_argument("--snapshot-dir", type=Path,
                     help="archive snapshot dir containing ProjectSummary.json.gz and Cluster.json.gz")
    src.add_argument("--project-summary", type=Path, help="ProjectSummary CSV export")
    src.add_argument("--cluster", type=Path, help="Cluster CSV export")
    p.add_argument("--vintage", required=True, help="snapshot date YYYY-MM-DD")
    p.add_argument("--out-dir", type=Path,
                   default=Path(__file__).resolve().parent.parent / "public" / "data",
                   help="output directory (default: public/data next to this script)")
    a = p.parse_args(argv)

    try:
        dt.date.fromisoformat(a.vintage)
    except ValueError:
        p.error("--vintage must be YYYY-MM-DD")

    if a.snapshot_dir and (a.project_summary or a.cluster):
        p.error("use either --snapshot-dir or --project-summary/--cluster, not both")
    if not a.snapshot_dir and not (a.project_summary and a.cluster):
        p.error("provide --snapshot-dir, or both --project-summary and --cluster")
    return a


def main(argv: list[str]) -> int:
    a = parse_args(argv)

    if a.snapshot_dir:
        ps_path = a.snapshot_dir / "ProjectSummary.json.gz"
        cl_path = a.snapshot_dir / "Cluster.json.gz"
        for pth in (ps_path, cl_path):
            if not pth.is_file():
                print(f"error: missing {pth}", file=sys.stderr)
                return 1
        projects = read_odata_gz(ps_path)
        clusters = read_odata_gz(cl_path)
    else:
        projects = read_csv(a.project_summary)
        clusters = read_csv(a.cluster)

    print(f"read {len(projects):,} ProjectSummary rows, {len(clusters):,} Cluster rows")

    cluster_map = primary_cluster_by_project(clusters)
    grants = build_grants(projects, cluster_map)
    meta = build_meta(grants, a.vintage)

    n_unknown = sum(1 for g in grants if g["cluster"] == CLUSTER_UNKNOWN)
    n_uncat = sum(1 for g in grants if g["org_type"] == ORG_TYPE_FALLBACK)
    print(f"kept {len(grants):,} grants (year >= {MIN_YEAR}, budget > 0); "
          f"{n_unknown:,} without cluster, {n_uncat:,} uncategorised org type")
    print(f"years {meta['year_min']}-{meta['year_max']}, {meta['n_funds']} funds, vintage {meta['snapshot_date']}")

    a.out_dir.mkdir(parents=True, exist_ok=True)
    grants_path = a.out_dir / "cbpf_grants.json"
    meta_path = a.out_dir / "cbpf_meta.json"
    with open(grants_path, "w", encoding="utf-8") as fh:
        json.dump(grants, fh, ensure_ascii=False, separators=(",", ":"))
    with open(meta_path, "w", encoding="utf-8") as fh:
        json.dump(meta, fh, ensure_ascii=False, indent=2)
        fh.write("\n")

    print(f"wrote {grants_path} ({os.path.getsize(grants_path) / 1e6:.2f} MB)")
    print(f"wrote {meta_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
