# Grant Size vs Number of Grants per Organisation — Shiny App

Interactive version of the static dot-chart from `ukraine-poolfund-report.qmd`
(section **#sec-org-dotchart**). Shows the full CBPF global dataset instead of
the 2022–2025 Ukraine-focused subset in the report.

## Features

| Control | What it does |
|---|---|
| Year range slider | Filter 2014–2025 (default 2022–2025) |
| Organisation type | Toggle INGO / NNGO / UN Agency |
| Context | Toggle Ukraine UHF / Global CBPF |
| Highlight org (search) | Gold rings appear on matching dots |
| Click a dot | Black ring; org name + metrics shown in sidebar |
| UHF Exception annotation | Toggle the parametric ellipse + label |
| Clip axes toggle | Lock axes to Ukraine range + buffer (default on) |
| Plotly toolbar | Zoom, pan, download PNG |

## Dependencies

```r
install.packages(c(
  "shiny", "dplyr", "ggplot2", "plotly",
  "readr", "scales", "tidyr", "glue"
))
```

## Run locally

From the repo root:

```r
shiny::runApp("shiny/grant-size-app")
```

Or navigate into the app folder and run:

```r
shiny::runApp()
```

## Deploy to the Shiny server (rsync)

The app folder is self-contained (`data/` holds the required CSVs).
Deploy with a single rsync command:

```bash
rsync -avz --delete \
  shiny/grant-size-app/ \
  <user>@<server>:/srv/shiny-server/grant-size-app/
```

After syncing, the app is available at:

```
http://<server>:3838/grant-size-app/
```

### Re-deploying after a data refresh

1. Copy updated CSVs into `shiny/grant-size-app/data/`:

   ```bash
   cp Raw-data/ProjectSummary_ALL_*.csv shiny/grant-size-app/data/ProjectSummary_ALL_20260219_100323_UTC.csv
   cp Raw-data/Cluster_ALL_*.csv        shiny/grant-size-app/data/Cluster_ALL_20260219_100323_UTC.csv
   ```

2. Re-run the rsync command above.

## Data

| File | Source |
|---|---|
| `data/ProjectSummary_ALL_20260219_100323_UTC.csv` | Copied from `Raw-data/` |
| `data/Cluster_ALL_20260219_100323_UTC.csv` | Copied from `Raw-data/` |

The data pipeline inside `app.R` is identical to the `grant-prep` chunk in
`ukraine-poolfund-report.qmd`: same filters, same `OrgType`/`Context` mutations,
same cluster name shortening. The only difference is that the chart-level year
filter is driven by the slider instead of being hardcoded to 2022–2025.
