#!/usr/bin/env Rscript
# Script to fetch CBPF data for all countries from UNOCHA API
# Created: February 13, 2026

library(httr)
library(readr)

# Base API URL
base_url <- "https://cbpfapi.unocha.org/vo1/odata"

# Output directory
output_dir <- "Raw-data"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Timestamp for file naming
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S_UTC")

# List of endpoints to fetch
endpoints <- c(
  "ProjectSummary",
  "AllocationFlow",
  "Contribution",
  "Cluster",
  "PipelineProjectSummary",
  "PipelineProjectCluster",
  "ProjectSummaryWithLocation",
  "ProjectSummaryWithLocationAndCluster"
)

cat("=", rep("=", 60), "=\n", sep = "")
cat("  CBPF Data Fetcher - All Countries\n")
cat("=" , rep("=", 60), "=\n", sep = "")
cat("\n")

# Function to fetch and save data
fetch_data <- function(endpoint) {
  cat(sprintf("Fetching %s...\n", endpoint))
  
  # Build URL - omit poolfundAbbrv to get all countries
  url <- sprintf("%s/%s?$format=csv", base_url, endpoint)
  
  tryCatch({
    # Make GET request
    response <- GET(url, timeout(300))
    
    # Check if request was successful
    if (status_code(response) == 200) {
      # Parse content
      content_text <- content(response, "text", encoding = "UTF-8")
      
      # Save to file
      output_file <- file.path(output_dir, sprintf("%s_ALL_%s.csv", endpoint, timestamp))
      write(content_text, output_file)
      
      # Get row count
      data <- read_csv(output_file, show_col_types = FALSE)
      row_count <- nrow(data)
      
      cat(sprintf("  ✓ Saved: %s (%d rows)\n", basename(output_file), row_count))
      return(TRUE)
    } else {
      cat(sprintf("  ✗ Failed: HTTP %d\n", status_code(response)))
      return(FALSE)
    }
  }, error = function(e) {
    cat(sprintf("  ✗ Error: %s\n", e$message))
    return(FALSE)
  })
}

# Fetch all endpoints
cat("\nFetching data from CBPF API...\n\n")
results <- sapply(endpoints, fetch_data)

# Summary
cat("\n")
cat("=" , rep("=", 60), "=\n", sep = "")
cat(sprintf("Summary: %d/%d endpoints fetched successfully\n", 
            sum(results), length(results)))
cat("=" , rep("=", 60), "=\n", sep = "")
cat("\n")

# List files
cat("Files saved in:", output_dir, "\n")
all_files <- list.files(output_dir, pattern = timestamp, full.names = FALSE)
for (f in all_files) {
  cat(sprintf("  - %s\n", f))
}
