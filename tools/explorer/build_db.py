#!/usr/bin/env python3
"""Build explorer/cbpf-explorer.sqlite from everything under Raw-data/.

Stdlib only. One SQLite table per dataset:
  csv__<Endpoint>__<vintage>          Raw-data/*.csv, Raw-data/vo2/*.csv, Raw-data/pipeline-vintages/*.csv
  arc__<YYYYMMDD>__<Endpoint>         Raw-data/archive/<day>/<Endpoint>.json.gz (vo1)
  arc__<YYYYMMDD>__vo2__<Endpoint>    Raw-data/archive/<day>/vo2/<Endpoint>.json.gz
plus a `_datasets` catalog and a Datasette metadata file with facets.

Usage: python3 tools/explorer/build_db.py [--out explorer/cbpf-explorer.sqlite] [--archive-days N]
"""
import argparse, csv, glob, gzip, json, os, re, sqlite3, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RAW = os.path.join(ROOT, "Raw-data")
csv.field_size_limit(sys.maxsize)

FACET_CANDIDATES = ["PooledFundName", "PoolfundName", "AllocationYear", "AllocationSourceName", "AllocationSource",
                    "OrganizationType", "OrgType", "Cluster", "ClusterName", "ProjectStatus", "ProcessStatus",
                    "snapshot_date", "FiscalYear", "DonorName", "GMSDonorName", "AdminLocation1", "FundingType",
                    "IndicatorType", "target", "year", "Country", "TypeOfAlloc"]

def safe_name(s):
    return re.sub(r"[^A-Za-z0-9_]", "_", s)

def infer_type(values):
    """int / real / text from a sample of non-empty strings."""
    seen_num = False
    for v in values:
        if v is None or v == "":
            continue
        try:
            int(v); seen_num = True; continue
        except ValueError:
            pass
        try:
            float(v); seen_num = True; continue
        except ValueError:
            return "TEXT"
    return "REAL" if seen_num else "TEXT"

def coerce(v, t):
    if v is None or v == "":
        return None
    if t == "TEXT":
        return v
    try:
        f = float(v)
        return int(f) if t == "INTEGER" or f.is_integer() else f
    except (ValueError, TypeError):
        return v

def load_rows_csv(path):
    with open(path, encoding="utf-8", newline="") as f:
        r = csv.reader(f)
        header = next(r)
        rows = list(r)
    return header, rows

def load_rows_json(path):
    with gzip.open(path, "rt", encoding="utf-8") as f:
        data = json.load(f)
    recs = data.get("value", data) if isinstance(data, dict) else data
    header = []
    for rec in recs:
        for k in rec:
            if k not in header:
                header.append(k)
    rows = [[rec.get(k) for k in header] for rec in recs]
    return header, rows

def create_table(con, name, header, rows, typed_from_json):
    cols = [safe_name(h) or f"col{i}" for i, h in enumerate(header)]
    # de-duplicate column names
    seen = {}
    for i, c in enumerate(cols):
        if c in seen:
            seen[c] += 1; cols[i] = f"{c}_{seen[c]}"
        else:
            seen[c] = 0
    if typed_from_json:
        types = []
        for i in range(len(cols)):
            sample = [r[i] for r in rows[:2000] if r[i] is not None]
            if sample and all(isinstance(x, bool) for x in sample): types.append("INTEGER")
            elif sample and all(isinstance(x, int) and not isinstance(x, bool) for x in sample): types.append("INTEGER")
            elif sample and all(isinstance(x, (int, float)) and not isinstance(x, bool) for x in sample): types.append("REAL")
            else: types.append("TEXT")
    else:
        types = [infer_type([r[i] for r in rows[:5000] if i < len(r)]) for i in range(len(cols))]
        rows = [[coerce(r[i] if i < len(r) else None, types[i]) for i in range(len(cols))] for r in rows]
    con.execute(f'DROP TABLE IF EXISTS "{name}"')
    con.execute(f'CREATE TABLE "{name}" ({", ".join(f"\"{c}\" {t}" for c, t in zip(cols, types))})')
    con.executemany(f'INSERT INTO "{name}" VALUES ({",".join("?" * len(cols))})', rows)
    return cols

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "explorer", "cbpf-explorer.sqlite"))
    ap.add_argument("--archive-days", type=int, default=1, help="how many of the newest archive days to load (0 = none)")
    args = ap.parse_args()
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    if os.path.exists(args.out):
        os.remove(args.out)
    con = sqlite3.connect(args.out)
    con.execute("PRAGMA journal_mode=OFF"); con.execute("PRAGMA synchronous=OFF")
    catalog = []
    facets = {}
    base_url = os.environ.get("EXPLORER_BASE", f"http://localhost:{os.environ.get('PORT', '8001')}/cbpf-explorer")

    def register(table, source, kind, vintage, header, cols, nrows, note=""):
        catalog.append((table, f"{base_url}/{table}", os.path.relpath(source, ROOT), kind, vintage, nrows, len(cols), note))
        fc = [c for c in cols if c in FACET_CANDIDATES][:6]
        if fc:
            facets[table] = fc
        print(f"  {table:60s} {nrows:>8,} rows  {len(cols):>3} cols", flush=True)

    # 1) CSV datasets
    print("CSV datasets")
    for path in sorted(glob.glob(os.path.join(RAW, "*.csv")) + glob.glob(os.path.join(RAW, "vo2", "*.csv")) + glob.glob(os.path.join(RAW, "pipeline-vintages", "*.csv"))):
        base = os.path.basename(path)[:-4]
        m = re.match(r"(.+?)_(?:ALL|daily)_(.+)$", base)
        endpoint, vintage = (m.group(1), m.group(2)) if m else (base, "")
        sub = "vo2__" if os.sep + "vo2" + os.sep in path else ("vintages__" if "pipeline-vintages" in path else "")
        table = f"csv__{sub}{safe_name(endpoint)}__{vintage}"
        with open(path, encoding="utf-8", errors="ignore") as fh:
            if fh.readline().lstrip().startswith("<"):
                print(f"  skipping {os.path.basename(path)}: HTML error page saved as CSV"); continue
        header, rows = load_rows_csv(path)
        cols = create_table(con, table, header, rows, typed_from_json=False)
        register(table, path, "csv", vintage, header, cols, len(rows))

    # 2) Archive days (json.gz), newest first
    days = sorted([d for d in os.listdir(os.path.join(RAW, "archive")) if re.match(r"\d{4}-\d{2}-\d{2}$", d)], reverse=True) if os.path.isdir(os.path.join(RAW, "archive")) else []
    for day in days[: args.archive_days]:
        print(f"Archive day {day}")
        ddir = os.path.join(RAW, "archive", day)
        for path in sorted(glob.glob(os.path.join(ddir, "*.json.gz")) + glob.glob(os.path.join(ddir, "vo2", "*.json.gz"))):
            endpoint = os.path.basename(path)[:-8]
            sub = "vo2__" if os.sep + "vo2" + os.sep in path else ""
            table = f"arc__{day.replace('-', '')}__{sub}{safe_name(endpoint)}"
            header, rows = load_rows_json(path)
            cols = create_table(con, table, header, rows, typed_from_json=True)
            register(table, path, "archive-vo2" if sub else "archive-vo1", day, header, cols, len(rows))

    # 3) Catalog + metadata
    con.execute("DROP TABLE IF EXISTS _datasets")
    con.execute("CREATE TABLE _datasets (table_name TEXT PRIMARY KEY, open TEXT, source_file TEXT, kind TEXT, vintage TEXT, rows INTEGER, columns INTEGER, note TEXT)")
    con.executemany("INSERT INTO _datasets VALUES (?,?,?,?,?,?,?,?)", catalog)
    # Convenience views on the newest archive day, if present
    if days and args.archive_days:
        d = days[0].replace("-", "")
        for ep in ["ProjectSummary", "Cluster", "Contribution", "PipelineProjectSummary"]:
            t = f"arc__{d}__{ep}"
            if con.execute("SELECT 1 FROM sqlite_master WHERE name=?", (t,)).fetchone():
                con.execute(f'CREATE VIEW IF NOT EXISTS "latest_{ep}" AS SELECT * FROM "{t}"')
                con.execute(f'CREATE VIEW IF NOT EXISTS "latest_{ep}_Ukraine" AS SELECT * FROM "{t}" WHERE PooledFundName = \'Ukraine\'')
    con.commit()
    # Indexes on common filter columns
    for (table, *_rest) in catalog:
        for c in facets.get(table, []):
            con.execute(f'CREATE INDEX IF NOT EXISTS "ix_{table}_{c}" ON "{table}"("{c}")')
    con.commit()
    con.execute("VACUUM")
    con.close()

    meta = {
        "title": "CBPF data explorer (internal)",
        "description": "Everything held in Raw-data/: the February 2026 extract, the 1 September 2026 vintage, daily pipeline vintages, vo2 pulls, and the newest synced archive day (vo1 + vo2 + LogicalFrameworkIndicator). Start with the _datasets table.",
        "databases": {"cbpf-explorer": {"tables": {t: {"facets": f} for t, f in facets.items()}}},
    }
    meta["databases"]["cbpf-explorer"]["tables"]["_datasets"] = {"facets": ["kind", "vintage"], "sort_desc": "rows"}
    with open(os.path.join(os.path.dirname(args.out), "metadata.json"), "w") as f:
        json.dump(meta, f, indent=1)
    print(f"\nWrote {args.out} ({os.path.getsize(args.out)/1e6:.0f} MB), {len(catalog)} tables; metadata.json alongside.")

if __name__ == "__main__":
    t0 = time.time(); main(); print(f"done in {time.time()-t0:.0f}s")
