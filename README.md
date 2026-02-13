# Ukraine Humanitarian Pooled Fund Analysis (2026)

Analysis of funding allocations, organizational performance, and beneficiary demographics for the Ukraine Humanitarian Pooled Fund.

## 📊 Project Overview

This repository contains a comprehensive analysis of the Ukraine Humanitarian Pooled Fund (UHF), examining:
- Funding distribution by organization type and year
- Project implementation and status
- Beneficiary demographics and reach
- 2025 funding trends and patterns

## 📑 Reports

- **[Main Analysis Report](ukraine-poolfund-report.html)** - Interactive HTML report with visualizations
- **[Analysis Script](analysis.R)** - R script with chunked analysis sections

## 🗂️ Repository Structure

```
├── analysis.R                    # Main R analysis script (with executable chunks)
├── ukraine-poolfund-report.qmd   # Quarto report source
├── ukraine-poolfund-report.html  # Generated HTML report
├── custom-style.css              # Custom styling for reports
├── Raw-data/                     # Source data files
├── R-project-template/           # Reusable project template
│   ├── .vscode/                  # VS Code configuration
│   ├── .Rprofile                 # R startup configuration
│   ├── custom-style.css          # Report styling
│   ├── quarto-template.qmd       # Quarto template
│   ├── install_packages.R        # Package installation
│   ├── setup_new_project.sh      # Automated setup script
│   └── USAGE_GUIDE.md            # Template documentation
└── README.md                     # This file
```

## 🚀 Getting Started

### Prerequisites

- R (version 4.5+)
- Quarto CLI
- Required R packages: dplyr, ggplot2, tidyr, readr, lubridate, stringr

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/2026-analysis-ukraine-poolfund.git
cd 2026-analysis-ukraine-poolfund
```

2. Install required R packages:
```bash
Rscript install_packages.R
```

3. Open in VS Code:
```bash
code .
```

### Running the Analysis

**Option 1: Run R Script Chunks**
- Open `analysis.R` in VS Code
- Use `Ctrl+Shift+Enter` to run individual chunks

**Option 2: Render Quarto Report**
```bash
quarto render ukraine-poolfund-report.qmd
```

## 📈 Key Findings

- **Total Projects**: Comprehensive analysis across multiple allocation years
- **2025 Focus**: In-depth analysis of 2025 funding distribution
- **Organization Types**: Including UN agencies, international NGOs, and national NGOs
- **Beneficiary Demographics**: Gender and age-disaggregated beneficiary data

## 🎨 Report Styling

This project uses custom styling with:
- **Fonts**: Lato (headers), Lora (body), Source Code Pro (code)
- **Color Scheme**: Professional teal/blue theme (#005f73, #2B638B)
- **Theme**: Yeti with custom CSS enhancements

## 🔧 Reusable Template

The `R-project-template/` folder contains a complete reusable configuration for starting new R/Quarto projects. See the [template usage guide](R-project-template/USAGE_GUIDE.md) for details.

### Quick Template Usage

```bash
# Create a new project using the template
./R-project-template/setup_new_project.sh ~/path/to/new-project "Project Name"
```

## 📦 Data Sources

- Allocation flow data
- Project summaries with location and cluster information
- Pipeline project data
- Contribution records
- Cluster definitions

## 🤝 Contributing

This is an analysis project. For questions or suggestions, please open an issue.

## 📄 License

This project is provided for analysis and educational purposes.

## 👤 Author

Ukraine Poolfund Analysis Team (2026)

---

*Generated using R, Quarto, and custom styling templates*
