# Grant Size vs Number of Grants per Organisation — v3 (Nuxt + R Plumber)

Interactive dot-chart replicating the Shiny v2 app, built with **Nuxt 4** and
data served by the R Plumber API at `rplumber.baena.info`.

Uses the same dark-theme design as [2026-mapping-casestudy-nikopol](../../2026-mapping-casestudy-nikopol/).

## Architecture

```
Browser (Nuxt 4 + Plotly.js + Tailwind)
  └── fetches on mount → rplumber.baena.info/cbpf/grants   (~16K grant records)
                        rplumber.baena.info/cbpf/meta    (year range, fund list)
  └── all filtering and aggregation done client-side
```

Data flow mirrors the Shiny v2 `app.R` pipeline:
same `OrgType` mapping, same cluster name shortening, same `budget > 0` filter.
The plumber API returns one row per individual grant; the Nuxt composable
`useChartFilters` aggregates to org×fund stats (n_grants, median size, total, health share).

## Features

| Control | What it does |
|---|---|
| Year range sliders | Filter 2014–2025 (default 2022–2025) |
| Organisation type | Toggle INGO / NNGO / UN Agency / Others |
| Funds multi-select | Select / deselect individual CBPF funds |
| Highlight org (search) | Gold rings appear on matching dots |
| Click a dot | Warm-sand ring; org name + metrics shown below sidebar |
| UHF Exception annotation | Toggle parametric ellipse + label |
| Clip axes toggle | Lock axes to Ukraine range + buffer |
| Plotly toolbar | Zoom, pan, download PNG |

## Dependencies

```bash
pnpm install
```

Requires Node 20+ and pnpm.

## Run locally

```bash
cd shiny/grant-size-app-v3
pnpm install
pnpm dev
```

The app runs at `http://localhost:3000`.

To override the API URL (e.g. point to a local plumber instance):

```bash
NUXT_PUBLIC_PLUMBER_BASE=http://localhost:8000 pnpm dev
```

## Build for production

```bash
pnpm generate   # static pre-rendered output in .output/public/
# or
pnpm build      # SSR build
```

## Deploy to Swarm (rsync)

The static output is self-contained. After `pnpm generate`:

```bash
rsync -avz --delete \
  .output/public/ \
  <user>@<server>:/srv/static/grant-size-app-v3/
```

## R Plumber API — first-time setup

The two new CBPF endpoints live in the **swarm-infrastructure** repo under
`analytics/plumber-api/`. Before building the Docker image, copy the latest CSVs:

```bash
cd /path/to/swarm-infrastructure

cp /path/to/poolfund-analysis/Raw-data/ProjectSummary_ALL_*.csv \
   analytics/plumber-api/data/ProjectSummary.csv

cp /path/to/poolfund-analysis/Raw-data/Cluster_ALL_*.csv \
   analytics/plumber-api/data/Cluster.csv
```

Then rebuild and redeploy the plumber image following the workflow in
`analytics/docker-compose.yml` (build locally → save → load on chernihiv → update service).

After deployment, verify:

```bash
curl https://rplumber.baena.info/health
curl https://rplumber.baena.info/cbpf/meta
curl https://rplumber.baena.info/cbpf/grants | head -c 500
```

## Project structure

```
shiny/grant-size-app-v3/
├── nuxt.config.ts          API base URL (runtimeConfig), Tailwind, fonts
├── tailwind.config.ts      Design tokens (warm-sand, teal, charcoal…)
├── package.json
├── app/
│   ├── app.vue             Root — <NuxtPage />
│   ├── assets/css/main.css Dark-theme base + scrollbar overrides
│   ├── types/cbpf.ts       GrantRecord, CbpfMeta, OrgStat, DOT_COLORS
│   ├── composables/
│   │   ├── useCbpfData.ts      Fetches /cbpf/grants + /cbpf/meta on mount
│   │   └── useChartFilters.ts  Reactive filter state + client-side aggregation
│   ├── components/
│   │   ├── SidebarPanel.vue    All sidebar controls (sliders, checkboxes, select)
│   │   ├── OrgInfoBox.vue      Clicked-org detail panel (bottom of sidebar)
│   │   └── DotChart.vue        Plotly.js scatter chart (ClientOnly)
│   └── pages/
│       └── index.vue           12-col grid wiring everything together
```

## Data

| Endpoint | Description |
|---|---|
| `GET /cbpf/meta` | `{ year_min, year_max, funds[] }` |
| `GET /cbpf/grants` | Array of `{ allocation_year, fund, org_name, org_type, budget, cluster }` |

Source CSVs: `Raw-data/ProjectSummary_ALL_20260219_100323_UTC.csv` and
`Raw-data/Cluster_ALL_20260219_100323_UTC.csv` (Feb 2026 CBPF extract).
