# CBPF Grant Size Explorer — v3 (Nuxt 4, static)

> **Superseded (October 2026).** The explorer has been re-imagined as a data
> story inside the portfolio site: `app/pages/demos/cbpf-grant-size.vue` in
> `2025-portfolio-professional-website` (route `/demos/cbpf-grant-size`, with
> `app/components/cbpf/*`, `app/composables/useCbpf*.ts`, `app/utils/cbpf.ts`).
> This folder stays as the **data contract**: `scripts/build_data.py` still
> produces the JSON the portfolio page reads. To refresh the portfolio copy:
>
> ```bash
> python3 scripts/build_data.py --snapshot-dir /path/to/snap/YYYY-MM-DD --vintage YYYY-MM-DD \
>   --out-dir /home/jbi/Git/2025-portfolio-professional-website/public/data/cbpf
> ```

Interactive dot chart of **grant size vs number of grants per organisation** across
UN Country-Based Pooled Funds (CBPF), with the Ukraine Humanitarian Fund (UHF)
highlighted. Replicates the chart from the
[Ukraine pooled-fund report](https://baena.ai/demos/ukraine-poolfund-report) and the
companion article [The UHF's twin tiers](https://baena.ai/articles/uhf-twin-tiers).
Author: Jesus Baena — [baena.ai](https://baena.ai).

Each dot = one organisation within one fund. x = number of grants, y = median grant
size (log), size = total USD, orange = Ukraine UHF, teal = other funds.

## Architecture

Fully static. No API or server-side runtime is needed in production.

```
scripts/build_data.py  ──►  public/data/cbpf_grants.json   (one row per grant, ~2.7 MB)
   (CBPF OData snapshot)     public/data/cbpf_meta.json     (year range, funds, snapshot date)

Browser (Nuxt 4 + plotly.js-basic + Tailwind)
   └── fetches /data/*.json on mount; all filtering + org×fund aggregation is client-side
```

An optional live backend is still supported: set `NUXT_PUBLIC_PLUMBER_BASE=https://host`
at build time and the app fetches `/cbpf/grants` and `/cbpf/meta` from there instead
(same JSON shapes). It is off by default.

## Data flow (mirrors the Quarto report / Shiny v2 `app.R`)

* Source: CBPF OData API, entity sets `ProjectSummary` and `Cluster`.
* Keep `AllocationYear >= 2014` and `Budget > 0` (nulls dropped). Years up to the
  latest in the data are kept; `year_max` in meta is data-driven.
* `OrganizationType` → `INGO`, `NNGO`, `UN Agency`, `Others`, `Red Cross`
  (Red Cross/Crescent), else `Other (uncategorised)`.
* Primary cluster per project = `Cluster` row with the highest `Percentage` for the
  `ChfProjectCode` (globally unique; `ChfId` is not). Names shortened:
  WASH, Shelter & NFI, Camp Coord./Mgmt, Coord. & Support, Telecoms. Missing → `Unknown`.
* `source` = `AllocationSourceName` (`Standard` / `Reserve`).
* In the browser, `useChartFilters` aggregates to org × fund: `n_grants`,
  `median_size` (median over the selected years), `total_usd`, `pct_health`
  (share of grants whose primary cluster is Health).

## Building the data

Python 3, standard library only.

```bash
# from an archive snapshot directory (gzipped OData JSON)
python3 scripts/build_data.py \
  --snapshot-dir /path/to/snap/2026-10-06 \
  --vintage 2026-10-06

# or from CSV exports
python3 scripts/build_data.py \
  --project-summary ../../Raw-data/ProjectSummary_ALL_20260901_snapshot.csv \
  --cluster         ../../Raw-data/Cluster_ALL_20260901_snapshot.csv \
  --vintage 2026-09-01
```

A snapshot directory must contain `ProjectSummary.json.gz` and `Cluster.json.gz`
(`{"value": [...]}`). Output goes to `public/data/` (override with `--out-dir`).
The snapshot date is shown in the sidebar and the About dialog.

`cbpf_grants.json` rows: `{allocation_year, fund, org_name, org_type, budget, cluster, source}`
(budget rounded to whole USD). `cbpf_meta.json`:
`{year_min, year_max, funds[], snapshot_date, n_grants, n_funds, built_at}`.

## Features

| Control | What it does |
|---|---|
| Year range sliders | Filter allocation years (default 2022–2025) |
| Organisation type | Checkboxes derived from the data; default INGO + NNGO |
| Allocation source | All / Standard / Reserve |
| Funds | Scrollable checkbox list with filter box; All / None / Ukraine only |
| Highlight org | Regex search; gold rings on matching dots |
| Click a dot / table row | Sand ring; org metrics shown under the sidebar |
| UHF Exception annotation | Dotted ellipse + label (calibrated for the 2022–2025 default view) |
| Focus axes | Clip axes to the Ukraine range + buffer |
| Chart / Table toggle | Sortable table of the current org×fund rows + **Download CSV** |
| Copy link | Copies the current URL (all state is in the query string) |
| About | What the chart shows, how to read it, data source and methodology |
| Plotly toolbar | Zoom, pan, PNG export |

Below the `lg` breakpoint (1024 px) the sidebar becomes a drawer toggled from the
top bar; the chart fills the remaining viewport.

## URL parameters

All filters are mirrored to the query string (`useUrlState.ts`) and restored on load.

| Param | Example | Notes |
|---|---|---|
| `years` | `years=2022-2025` | always present |
| `types` | `types=INGO,UN+Agency` | omitted when default (INGO + NNGO) |
| `funds` | `funds=Ukraine,Syria` | omitted when all funds selected; `funds=none` = empty |
| `source` | `source=Reserve` | omitted when All |
| `q` | `q=unicef` | highlight search |
| `ellipse` | `ellipse=1` | annotation on |
| `clip` | `clip=0` | axis clipping off (default on) |
| `org` | `org=Ukraine\|Org name` | selected org as `fund|name` |
| `view` | `view=table` | table view (omitted for chart) |

Example: `/?years=2022-2025&funds=Ukraine&q=Caritas&ellipse=1`

## Develop

Requires Node 22 and pnpm 10.

```bash
pnpm install --frozen-lockfile
pnpm dev          # http://localhost:3000
```

## Build and deploy

```bash
pnpm generate                      # static site in .output/public/
npx serve -l 4173 .output/public   # local check
```

The output is self-contained (HTML + `_nuxt/` assets + `data/` + `favicon.svg`).
Deploy with rsync to any static host:

```bash
rsync -avz --delete .output/public/ <user>@<server>:/srv/static/grant-size-app-v3/
```

Client bundle: ~1.1 MB Plotly basic bundle (gzip ~380 kB) + ~230 kB app/Vue, plus
~2.7 MB grants JSON (compresses well; enable gzip/brotli on the host).

## Refreshing the data

1. Obtain a new CBPF OData snapshot (archive directory or CSV exports).
2. Run `scripts/build_data.py` with the matching `--vintage` date.
3. `pnpm generate` and rsync `.output/public/`.

No code changes are needed when new years or funds appear; year range, fund list
and org types are all read from the data.

## Project structure

```
shiny/grant-size-app-v3/
├── scripts/build_data.py       OData/CSV → public/data/*.json
├── public/
│   ├── data/cbpf_grants.json   built data (committed)
│   ├── data/cbpf_meta.json
│   └── favicon.svg
├── nuxt.config.ts              head/meta (OG, Twitter, theme-color), Tailwind, fonts
├── tailwind.config.ts          Design tokens (warm-sand, teal, charcoal…)
└── app/
    ├── assets/css/main.css     Dark-theme base, scrollbars, Plotly modebar colours
    ├── types/cbpf.ts           GrantRecord, CbpfMeta, OrgStat, formatters, constants
    ├── composables/
    │   ├── useCbpfData.ts      Loads /data/*.json (or plumber API)
    │   ├── useChartFilters.ts  Filter state + client-side org×fund aggregation
    │   └── useUrlState.ts      Query-string sync (read on load, write on change)
    ├── components/
    │   ├── SidebarPanel.vue    Controls (years, org types, source, funds, search, toggles)
    │   ├── FundSelector.vue    Checkbox list with filter + shortcuts
    │   ├── OrgInfoBox.vue      Selected org details
    │   ├── DotChart.vue        Plotly scatter (ClientOnly, plotly.js-basic-dist-min)
    │   ├── StatsTable.vue      Sortable table + CSV download
    │   └── AboutModal.vue      About / methodology dialog
    └── pages/index.vue         Layout, drawer, view toggle, copy link
```
