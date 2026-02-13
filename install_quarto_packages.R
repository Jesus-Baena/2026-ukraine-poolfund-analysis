# Install packages needed for Quarto rendering
install.packages(c("rmarkdown", "knitr"), 
                 repos = "https://cloud.r-project.org/",
                 dependencies = TRUE)
cat("\n\n=== Quarto Packages Installed! ===\n")
