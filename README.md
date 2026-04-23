# Ukraine Humanitarian Pooled Fund Analysis (2026)

Analysis of funding allocations, organizational performance, and beneficiary demographics for the Ukraine Humanitarian Pooled Fund.

## 📊 Project Overview

This repository contains a comprehensive analysis of the Ukraine Humanitarian Pooled Fund (UHF), examining:
- Funding distribution by organization type and year
- Project implementation and status
- Beneficiary demographics and reach
- 2025 funding trends and patterns

## 📑 Main Resources

**View the full analysis:**
- **[Ukraine Poolfund Report (Interactive Dashboard)](http://baena.ai/demos/ukraine-poolfund-report)** – Full interactive report with visualizations and data exploration
- **[UHF Twin Tiers Article (Explanatory Deep-Dive)](http://baena.ai/articles/uhf-twin-tiers)** – Detailed article explaining the analysis methodology and key findings

**Local Reports:**
- **[Main Analysis Report](ukraine-poolfund-report.html)** - Interactive HTML report with visualizations
- **[Analysis Script](analysis.R)** - R script with chunked analysis sections

## 📊 Project Details

### What This Project Does

This analysis examines the **Ukraine Humanitarian Pooled Fund (UHF)** – a coordinated funding mechanism that channels donor resources to humanitarian organizations responding to the crisis in Ukraine. The project uses the CBPF OData API to extract, clean, and analyze:

- **Funding allocations** across participating organizations
- **Project implementation status** and timelines
- **Organizational performance** (UN agencies, international NGOs, national NGOs)
- **Beneficiary demographics** including gender and age disaggregation
- **Funding trends** across allocation years (2010-2025, with focus on 2025)

### Key Findings

✅ **16,305 approved projects** spanning 2010-2025  
✅ **Multi-tier funding structure** - analysis reveals the "twin tiers" of funding flows documented in the explanatory article  
✅ **2025 allocations** show distinct patterns in organization types receiving funding  
✅ **Geographic and sectoral distribution** of beneficiary assistance  
✅ **Approval pipeline data** (581 projects) from 2013-2015, 2022, 2025-2026

See the [UHF Twin Tiers Article](http://baena.ai/articles/uhf-twin-tiers) for detailed methodology and analysis of how these funding patterns function.

---

## ⚠️ API Limitations & Data Gaps

The analysis relies on the **CBPF OData API** maintained by OCHA. This powerful data source has significant limitations that affect what insights are possible:

### Working Endpoints (Used in This Project)

| Endpoint | Records | Purpose |
|----------|---------|---------|
| **ProjectSummary** | 16,305 | Approved/implemented projects (main dataset) |
| **PipelineProjectSummary** | 581 | Projects under review, rejected, or pending |
| **ProjectSummaryWithLocation** | Large | Projects with geographic data |
| **Cluster** | Medium | Sector/cluster definitions |
| **Contribution** | Medium | Donor contributions |
| **PipelineProjectCluster** | Medium | Cluster assignments for pending projects |

### Critical Issues

❌ **~35 High-Value Endpoints Return 500 Errors:**
- Financial reporting (Budget, CostTracking, DisbursementMilestone)
- Narrative reporting (NarrativeReportBeneficiary, NarrativeReportSummary)
- Project planning (LogicalFramework, Workplan)
- Partner tracking (PartnerDueDiligence, PartnerCA)
- Process monitoring (CBPFInstanceStatus, CBPFProjectScorecard)
- Detailed beneficiary data endpoints

❌ **Sparse Historical Pipeline Data:**
- Pipeline records only available for 2013-2015, 2022, 2025-2026
- **No pipeline data for 2016-2021 or 2023-2024** – cannot calculate historical approval rates
- Cannot analyze rejection patterns for most allocation years

❌ **Limited Rejection Details:**
- Only 123 cancelled/archived projects available in API
- No explanatory text for rejections – only status codes
- Cannot filter pipeline data by status reliably

### Impact on Analysis

**What This Means:**
- ✅ Can analyze **approved project funding** comprehensively (2010-2025)
- ✅ Can see **recent pipeline activity** (2025-2026)
- ❌ **Cannot** analyze detailed financial disbursements or cost tracking
- ❌ **Cannot** access beneficiary narratives from project reports
- ❌ **Cannot** calculate historical approval/rejection rates (2016-2024 gap)
- ❌ **Cannot** access detailed work plans or logical frameworks

**Workaround:**
This project focuses on what's available: approved projects, funding flows, and organization/cluster distribution. The article discusses these constraints and explains how to interpret findings within these limits.

---

## 📂 Repository Structure

```
├── analysis.R                    # Main R analysis script (with executable chunks)
├── ukraine-poolfund-report.qmd   # Quarto report source
├── ukraine-poolfund-report.html  # Generated HTML report
├── custom-style.css              # Custom styling for reports
├── Raw-data/                     # Source data files (downloaded from CBPF API)
├── R-project-template/           # Reusable R/Quarto project template
│   ├── .vscode/                  # VS Code configuration
│   ├── .Rprofile                 # R startup configuration
│   ├── custom-style.css          # Report styling
│   ├── quarto-template.qmd       # Quarto template
│   ├── install_packages.R        # Package installation script
│   ├── setup_new_project.sh      # Automated setup script
│   └── USAGE_GUIDE.md            # Template documentation
├── API_FINDINGS.md               # Detailed API research notes
├── AVAILABLE_ENDPOINTS.md        # Complete API endpoint inventory
└── README.md                     # This file
```

## 🚀 Getting Started

### Prerequisites

- R (version 4.5+)
- Quarto CLI
- Required R packages: `dplyr`, `ggplot2`, `tidyr`, `readr`, `lubridate`, `stringr`

### Running the Analysis

**Option 1: Interactive Chunks (VS Code)**
- Open `analysis.R` in VS Code
- Use `Ctrl+Shift+Enter` to run individual chunks

**Option 2: Render Full Report**
```bash
quarto render ukraine-poolfund-report.qmd
```

This generates an interactive HTML report with all visualizations and tables.

---

## 📚 Documentation

- **[API_FINDINGS.md](API_FINDINGS.md)** — Detailed research on what data is available and why
- **[AVAILABLE_ENDPOINTS.md](AVAILABLE_ENDPOINTS.md)** — Complete inventory of 50 CBPF API endpoints (working, broken, and untested)

## 📦 Data Source

**CBPF OData API:** https://cbpfapi.unocha.org/vo1/odata  
**HDX Dataset:** https://data.humdata.org/dataset/cbpf-allocations-and-contributions

## 🤝 Contributing

Questions or suggestions? Please open an issue.

## 📄 License

This project is provided for analysis and educational purposes.

## 👤 Author

Ukraine Poolfund Analysis Team (2026)

---

*Built with R, Quarto, and CBPF API data. Analysis available at [baena.ai](http://baena.ai)*
