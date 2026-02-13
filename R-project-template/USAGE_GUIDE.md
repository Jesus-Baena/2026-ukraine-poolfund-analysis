# Reusing Your R/Quarto Configuration Across Projects

You now have a reusable project template in the `R-project-template/` folder!

## 📁 What's in the Template

```
R-project-template/
├── .vscode/
│   └── settings.json         # VS Code R configuration
├── .Rprofile                 # R startup script
├── custom-style.css          # CSS styling for reports
├── quarto-template.qmd       # Base Quarto document
├── install_packages.R        # Package installation
├── setup_new_project.sh      # Automated setup script
└── README.md                 # Documentation
```

## 🚀 Three Ways to Use This Template

### Option 1: Automated Setup (Recommended)

```bash
# Create a new project with one command
~/Git/2026-analysis-ukraine-poolfund/R-project-template/setup_new_project.sh \
  ~/Git/my-new-project "My New Analysis"

cd ~/Git/my-new-project
code .
Rscript install_packages.R
```

### Option 2: Manual Copy

```bash
# Create new project folder
mkdir ~/Git/my-new-project
cd ~/Git/my-new-project

# Copy template files
cp -r ~/Git/2026-analysis-ukraine-poolfund/R-project-template/.vscode .
cp ~/Git/2026-analysis-ukraine-poolfund/R-project-template/.Rprofile .
cp ~/Git/2026-analysis-ukraine-poolfund/R-project-template/custom-style.css .
cp ~/Git/2026-analysis-ukraine-poolfund/R-project-template/quarto-template.qmd analysis.qmd
cp ~/Git/2026-analysis-ukraine-poolfund/R-project-template/install_packages.R .

# Create data folders
mkdir Raw-data output scripts

# Open in VS Code
code .
```

### Option 3: Move Template to Home Directory (Best for Long-term)

```bash
# Move template to a central location
mv ~/Git/2026-analysis-ukraine-poolfund/R-project-template ~/.r-template

# Add alias to your .bashrc for quick access
echo "alias new-r-project='~/.r-template/setup_new_project.sh'" >> ~/.bashrc
source ~/.bashrc

# Now you can create projects from anywhere:
new-r-project ~/projects/analysis-2026 "2026 Analysis"
```

## 🎨 Styling Components

### Custom CSS (`custom-style.css`)
- **Fonts**: Lato (headers), Lora (body), Source Code Pro (code)
- **Colors**: 
  - Primary: `#005f73` (teal)
  - Secondary: `#2B638B` (blue)
  - Accent: `#c7254e` (red)
- **Features**: Styled tables, code blocks, TOC, callouts

### ggplot2 Theme
The Quarto template includes a custom ggplot2 theme in the setup chunk that matches the CSS styling. All plots will automatically use the same color scheme.

### VS Code Configuration
- R language server enabled
- Proper terminal integration
- Code formatting settings

## 🔄 Updating the Template

When you improve your workflow, update the template:

```bash
cd ~/Git/2026-analysis-ukraine-poolfund/R-project-template

# Update any file you want
# Then future projects will get the new version
```

## 📦 Essential Packages Included

The `install_packages.R` script installs:
- **Data wrangling**: dplyr, tidyr, readr, lubridate, stringr
- **Visualization**: ggplot2, scales
- **Reporting**: rmarkdown, knitr
- **Utilities**: forcats, janitor

## 💡 Tips

1. **Version Control**: Use git in the template folder to track changes
2. **Custom Modifications**: Edit template files before creating new projects
3. **Shareable**: Share the `R-project-template/` folder with colleagues
4. **Backup**: Keep a backup of your template configuration

## 🆘 Troubleshooting

**Packages not installing?**
```bash
# Install system dependencies first
sudo apt-get install libxml2-dev libcurl4-openssl-dev libssl-dev \
  libfontconfig1-dev libharfbuzz-dev libfribidi-dev
```

**Quarto not found?**
```bash
# Check installation
quarto --version

# If missing, template includes note to install
```

**R terminal not working?**
- Reload VS Code window after copying `.vscode/settings.json`
- Check that `.Rprofile` is in the project root

## 📚 Further Customization

Edit these files in the template to customize:
- `quarto-template.qmd` - Change default YAML options, theme setup
- `custom-style.css` - Modify colors, fonts, spacing
- `.Rprofile` - Add custom startup messages or functions
- `install_packages.R` - Add/remove default packages

---

*Template created from the Ukraine Poolfund Analysis project (2026)*
