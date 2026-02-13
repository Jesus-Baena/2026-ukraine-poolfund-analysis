#!/bin/bash
# Quick setup script for new R/Quarto projects
# Usage: ./setup_new_project.sh /path/to/new/project "Project Name"

if [ $# -lt 1 ]; then
    echo "Usage: $0 /path/to/new/project [Project Name]"
    exit 1
fi

PROJECT_PATH=$1
PROJECT_NAME=${2:-"My Project"}
TEMPLATE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Setting up new R project at: $PROJECT_PATH"
echo "Project name: $PROJECT_NAME"

# Create project directory
mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH"

# Create standard folders
mkdir -p Raw-data
mkdir -p output
mkdir -p scripts

# Copy configuration files
echo "Copying configuration files..."
cp -r "$TEMPLATE_DIR/.vscode" .
cp "$TEMPLATE_DIR/.Rprofile" .
cp "$TEMPLATE_DIR/custom-style.css" .
cp "$TEMPLATE_DIR/install_packages.R" .

# Create analysis file from template
cp "$TEMPLATE_DIR/quarto-template.qmd" analysis.qmd
sed -i "s/Your Project Title/$PROJECT_NAME/" analysis.qmd
sed -i "s/Your Name/$USER/" analysis.qmd

# Update .Rprofile with project name
sed -i "s/Ukraine Poolfund Analysis Project/$PROJECT_NAME/" .Rprofile

echo ""
echo "✓ Project setup complete!"
echo ""
echo "Next steps:"
echo "1. cd $PROJECT_PATH"
echo "2. Open in VS Code: code ."
echo "3. Install packages: Rscript install_packages.R"
echo "4. Start editing: analysis.qmd"
echo ""
