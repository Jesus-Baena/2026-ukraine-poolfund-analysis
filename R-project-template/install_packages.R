# Package Installation Script
# Run this once when setting up a new project

# Core data analysis packages
install.packages(c("dplyr", "ggplot2", "tidyr", "readr", "lubridate", "stringr"), 
                 repos = "https://cloud.r-project.org/",
                 dependencies = TRUE)

# Quarto/RMarkdown packages
install.packages(c("rmarkdown", "knitr"), 
                 repos = "https://cloud.r-project.org/",
                 dependencies = TRUE)

# Additional useful packages
install.packages(c("scales", "forcats", "janitor"), 
                 repos = "https://cloud.r-project.org/",
                 dependencies = TRUE)

cat("\n=== All packages installed successfully! ===\n")
