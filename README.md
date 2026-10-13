# Ukraine Humanitarian Pooled Fund Analysis

Analysis of allocation patterns, partner concentration, grant scale, and the health sector in the Ukraine Humanitarian Fund (UHF) using CBPF OData API data.

**Author:** Jesus Baena

---

## Published outputs

| | |
|---|---|
| **Interactive report** | [baena.ai/demos/ukraine-poolfund-report](https://baena.ai/demos/ukraine-poolfund-report) |
| **Companion article** | [baena.ai/articles/uhf-twin-tiers](https://baena.ai/articles/uhf-twin-tiers) |
| **Annex: January–August 2026** | `ukraine-poolfund-annex-2026-08.html` (rendered from the 1 September 2026 archive vintage) |

---

## Repository contents

| Path | Description |
|---|---|
| `ukraine-poolfund-report.qmd` | Quarto source for the interactive report |
| `ukraine-poolfund-report.html` | Rendered HTML report |
| `ukraine-poolfund-annex-2026-08.qmd` / `.html` | Annex covering January–August 2026: allocations, contributions, partners, sectors, pipeline, data revisions |
| `uhf_article_draft.md` / `.html` | Companion article draft |
| `API_FINDINGS.md` | CBPF OData API research findings |
| `AVAILABLE_ENDPOINTS.md` | Available API endpoints reference |
| `CBPF_API_GUIDE.md` | API usage guide |
| `blog_post_cbpf_api_constraints.md` | Notes on API limitations |
| `Raw-data/*_20260219_*.csv` | February 2026 extract used by the main report |
| `Raw-data/*_20260901_snapshot.csv` | 1 September 2026 archive vintage used by the annex (ISO dates) |
| `Raw-data/pipeline-vintages/` | Daily `PipelineProjectSummary` / `PipelineProjectCluster` vintages, 29 Aug – 6 Oct 2026, long format with `snapshot_date` |
| `Raw-data/vo2/` | Full pulls of the small vo2 endpoints (allocation-round register, allocation flows, contribution totals, masters), 6 Oct 2026 |
| `shiny/grant-size-app-v2/` | Shiny app (R) for grant size exploration, deployed at shiny.baena.info/uhf-grant-size-2025 |
| `tools/explorer/` | Internal data explorer: builds one SQLite file from everything in `Raw-data/` and serves it with Datasette (see below) |
| `shiny/grant-size-app-v3/` | Static Nuxt 4 rewrite of the same explorer (current data, shareable URLs, table view, mobile layout); see its README |

---

## Data

The main report uses a one-off extract of the [CBPF OData API](https://cbpfapi.unocha.org/vo1/odata) taken on 19 February 2026. Since 29 August 2026 the API is snapshotted daily by the swarm `harvest` stack (`2025-swarm-infrastructure-deployment/harvest/cbpf-snapshot.sh`) into `archive/cbpf/YYYY-MM-DD/`; the annex is built from the 1 September 2026 vintage. The October 2026 update of `API_FINDINGS.md` records a second API version (`vo2`, 24 working endpoints) and the current status of every vo1 endpoint.

Date formats differ between the two generations of CSV: the February files use the API's `m/d/Y h:m:s AM` strings, the snapshot files carry ISO 8601.


## Internal data explorer

Everything in `Raw-data/` (February 2026 extract, 1 September 2026 vintage, daily pipeline vintages, vo2 pulls, and any synced archive day with its `vo2/` folder and the weekly `LogicalFrameworkIndicator`) in one SQLite file, browsed with [Datasette](https://datasette.io): filters, facets, column sorting, SQL, CSV/JSON export.

```bash
tools/explorer/sync_archive.sh          # optional: pull the newest complete archive day from the swarm into Raw-data/archive/<day>/
tools/explorer/explore.sh               # builds explorer/cbpf-explorer.sqlite if needed (~12 s) and opens http://localhost:8001
```

Start with the `_datasets` table: one row per loaded table with source file, kind (`csv`, `archive-vo1`, `archive-vo2`), vintage and row count. Table names are `csv__<Endpoint>__<vintage>`, `csv__vo2__…`, `csv__vintages__…` and `arc__<YYYYMMDD>__[vo2__]<Endpoint>`; `latest_ProjectSummary`, `latest_ProjectSummary_Ukraine` and similar views point at the newest archive day. Needs Python 3 (stdlib only) and `uv` (`uvx datasette`). The SQLite file and `Raw-data/archive/` are gitignored.

The Postgres database on the swarm (`CBPF.raw_data`, refreshed daily by the collector) holds only the seven vo1 project tables; the vo2 endpoints and the logframe indicators exist in the daily archive files, which is what the explorer reads.
