# R Project Template - README

This folder contains reusable configurations and styling for R/Quarto projects.

## What to copy to new projects:

### 1. R Configuration
- `.vscode/settings.json` - VS Code R extension settings
- `.Rprofile` - R startup configuration

### 2. Quarto/RMarkdown Styling  
- `custom-style.css` - Custom CSS for HTML reports
- `quarto-template.qmd` - Base template for Quarto documents

### 3. Scripts
- `install_packages.R` - Package installation script

## Quick Setup for New Project:

1. Create new project folder
2. Copy files from this template:
   ```bash
   cp -r ~/R-project-template/.vscode ~/your-new-project/
   cp ~/R-project-template/.Rprofile ~/your-new-project/
   cp ~/R-project-template/custom-style.css ~/your-new-project/
   ```

3. Update `.Rprofile` with new project name
4. Start working!

## Color Scheme Reference:
- Primary: #005f73 (teal)
- Secondary: #2B638B (blue)
- Accent: #c7254e (red)
- Light background: #eef7f7

## Fonts Used:
- Headers: 'Lato', sans-serif
- Body: 'Lora', serif  
- Code: 'Source Code Pro', monospace
