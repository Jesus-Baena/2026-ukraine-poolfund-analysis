# R Profile for this project
# This file is loaded when R starts in this directory

# Set options for better terminal experience
options(
  repos = c(CRAN = "https://cloud.r-project.org/"),
  browserNLdisabled = TRUE,
  deparse.max.lines = 2,
  width = 120
)

# Enable auto-completion in terminal
utils::rc.settings(ipck = TRUE)

# Load commonly used libraries silently
.First <- function() {
  cat("\n")
  cat("===========================================\n")
  cat("  Ukraine Poolfund Analysis Project       \n")
  cat("===========================================\n")
  cat("\n")
  cat("Working directory:", getwd(), "\n")
  cat("R version:", R.version$version.string, "\n\n")
  cat("Tip: Use Tab for auto-completion\n")
  cat("Tip: Run source('analysis.R') to load data\n")
  cat("\n")
}
