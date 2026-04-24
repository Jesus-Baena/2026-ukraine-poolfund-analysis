# Ukraine Humanitarian Pooled Fund Analysis

Analysis of allocation patterns, partner concentration, grant scale, and the health sector in the Ukraine Humanitarian Fund (UHF) using CBPF OData API data.

**Author:** Jesus Baena

---

## Published outputs

| | |
|---|---|
| **Interactive report** | [baena.ai/demos/ukraine-poolfund-report](https://baena.ai/demos/ukraine-poolfund-report) |
| **Companion article** | [baena.ai/articles/uhf-twin-tiers](https://baena.ai/articles/uhf-twin-tiers) |

---

## Repository contents

| Path | Description |
|---|---|
| `ukraine-poolfund-report.qmd` | Quarto source for the interactive report |
| `ukraine-poolfund-report.html` | Rendered HTML report |
| `uhf_article_draft.md` / `.html` | Companion article draft |
| `API_FINDINGS.md` | CBPF OData API research findings |
| `AVAILABLE_ENDPOINTS.md` | Available API endpoints reference |
| `CBPF_API_GUIDE.md` | API usage guide |
| `blog_post_cbpf_api_constraints.md` | Notes on API limitations |
| `Raw-data/` | Source CSV data pulled from the CBPF API (February 2026) |
| `shiny/grant-size-app-v2/` | Shiny app (R) for grant size exploration |

---

## Data

Raw data was fetched from the [CBPF OData API](https://cbpf.unocha.org) in February 2026 and covers UHF allocations through early 2026. See `API_FINDINGS.md` for a full account of available endpoints and known limitations.
