# Ukraine Poolfund Data Analysis
# Created: February 13, 2026
# 
# This script provides initial data exploration and analysis for Ukraine 
# humanitarian poolfund data
#
# Run each chunk using Ctrl+Enter (current line) or Ctrl+Shift+Enter (entire chunk)
# Or click the "Run" button that appears above each section heading

# SETUP: Install Packages (run once) ----
# Run this chunk FIRST if packages are not installed
# Installing only essential packages instead of full tidyverse
if (!require("dplyr", quietly = TRUE)) {
  install.packages("dplyr", repos = "https://cloud.r-project.org/")
}
if (!require("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2", repos = "https://cloud.r-project.org/")
}
if (!require("tidyr", quietly = TRUE)) {
  install.packages("tidyr", repos = "https://cloud.r-project.org/")
}
if (!require("readr", quietly = TRUE)) {
  install.packages("readr", repos = "https://cloud.r-project.org/")
}
if (!require("lubridate", quietly = TRUE)) {
  install.packages("lubridate", repos = "https://cloud.r-project.org/")
}
if (!require("stringr", quietly = TRUE)) {
  install.packages("stringr", repos = "https://cloud.r-project.org/")
}

# SETUP: Load Libraries ----
library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
library(lubridate)
library(stringr)

# Set working directory
setwd("/home/jbi/Git/2026-ukraine-poolfund-analysis")

# CHUNK 1: Load All Data Files ----
cat("Loading data files...\n")

# Allocation flow data
allocation_flow <- read_csv("Raw-data/AllocationFlow__20260213_094810_UTC.csv")

# Project summaries
project_summary <- read_csv("Raw-data/ProjectSummary20260213095023733.csv")
project_summary_location <- read_csv("Raw-data/ProjectSummaryWithLocation20260213095148892.csv")
project_summary_cluster <- read_csv("Raw-data/ProjectSummaryWithLocationAndCluster20260213095151165.csv")

# Pipeline projects
pipeline_summary <- read_csv("Raw-data/PipelineProjectSummary20260213095153268.csv")
pipeline_cluster <- read_csv("Raw-data/PipelineProjectCluster20260213095156107.csv")

# Clusters and contributions
clusters <- read_csv("Raw-data/Cluster20260213095154538.csv")
contributions <- read_csv("Raw-data/Contribution20260213095157629.csv")

cat("Data loaded successfully!\n\n")

# CHUNK 2: Dataset Overview ----
cat("=== DATASET OVERVIEW ===\n")
cat("Allocation Flow:", nrow(allocation_flow), "rows,", ncol(allocation_flow), "columns\n")
cat("Project Summary:", nrow(project_summary), "rows,", ncol(project_summary), "columns\n")
cat("Project Summary (Location):", nrow(project_summary_location), "rows,", ncol(project_summary_location), "columns\n")
cat("Project Summary (Cluster):", nrow(project_summary_cluster), "rows,", ncol(project_summary_cluster), "columns\n")
cat("Pipeline Summary:", nrow(pipeline_summary), "rows,", ncol(pipeline_summary), "columns\n")
cat("Clusters:", nrow(clusters), "rows,", ncol(clusters), "columns\n")
cat("Contributions:", nrow(contributions), "rows,", ncol(contributions), "columns\n\n")

# CHUNK 3: Allocation Flow Summary ----
cat("=== ALLOCATION FLOW SUMMARY ===\n")
cat("Countries in dataset:", paste(unique(allocation_flow$Fund), collapse = ", "), "\n")

# Filter for Ukraine if multi-country dataset
ukraine_allocation <- allocation_flow %>%
  filter(Fund == "Ukraine")

if(nrow(ukraine_allocation) > 0) {
  cat("\nUkraine Allocation Summary:\n")
  ukraine_summary <- ukraine_allocation %>%
    group_by(Year, `Partner type`) %>%
    summarise(
      Total_Direct = sum(`Direct funding`, na.rm = TRUE),
      Total_Net = sum(`Net funding`, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    arrange(Year, desc(Total_Net))
  
  print(ukraine_summary)
} else {
  cat("Note: No Ukraine-specific data found in allocation flow.\n")
}

# CHUNK 4: Data Preprocessing ----
cat("\n=== DATA PREPROCESSING ===\n")

# Date parsing (if not already parsed)
project_summary <- project_summary %>%
  mutate(
    ProjectStartDate = mdy_hms(ProjectStartDate),
    ProjectEndDate = mdy_hms(ProjectEndDate)
  )

cat("Dates parsed successfully!\n")

# CHUNK 5: Projects by Organization Type ----
cat("\n=== PROJECTS BY ORGANIZATION TYPE ===\n")
org_type_summary <- project_summary %>%
  count(OrganizationType, name = "Projects") %>%
  arrange(desc(Projects))
print(org_type_summary)

# CHUNK 6: Projects by Year ----
cat("\n=== PROJECTS BY ALLOCATION YEAR ===\n")
year_summary <- project_summary %>%
  count(AllocationYear, name = "Projects") %>%
  arrange(AllocationYear)
print(year_summary)

# CHUNK 7: Budget Analysis ----
cat("\n=== BUDGET SUMMARY ===\n")
budget_stats <- project_summary %>%
  summarise(
    Total_Budget = sum(Budget, na.rm = TRUE),
    Mean_Budget = mean(Budget, na.rm = TRUE),
    Median_Budget = median(Budget, na.rm = TRUE),
    Min_Budget = min(Budget, na.rm = TRUE),
    Max_Budget = max(Budget, na.rm = TRUE)
  )
print(budget_stats)

# CHUNK 8: Beneficiary Analysis ----
cat("\n=== BENEFICIARY ANALYSIS ===\n")

beneficiary_totals <- project_summary %>%
  summarise(
    Total_Men = sum(Men, na.rm = TRUE),
    Total_Women = sum(Women, na.rm = TRUE),
    Total_Boys = sum(Boys, na.rm = TRUE),
    Total_Girls = sum(Girls, na.rm = TRUE)
  ) %>%
  mutate(
    Total_Adults = Total_Men + Total_Women,
    Total_Children = Total_Boys + Total_Girls,
    Grand_Total = Total_Adults + Total_Children
  )

print(beneficiary_totals)

# Gender distribution
cat("\nGender Distribution:\n")
cat("Female (Women + Girls):", beneficiary_totals$Total_Women + beneficiary_totals$Total_Girls, "\n")
cat("Male (Men + Boys):", beneficiary_totals$Total_Men + beneficiary_totals$Total_Boys, "\n")

# CHUNK 9: Project Status Overview ----
cat("\n=== PROJECT STATUS OVERVIEW ===\n")
status_summary <- project_summary %>%
  count(ProjectStatus, name = "Count") %>%
  arrange(desc(Count))
print(status_summary)

# CHUNK 10: Visualization - Budget by Organization ----
cat("\n=== VIZ 1: Budget by Organization Type ===\n")

p1 <- project_summary %>%
  group_by(OrganizationType) %>%
  summarise(Total_Budget = sum(Budget, na.rm = TRUE)) %>%
  ggplot(aes(x = reorder(OrganizationType, Total_Budget), y = Total_Budget/1e6)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Total Budget by Organization Type",
    x = "Organization Type",
    y = "Total Budget (Millions USD)"
  ) +
  theme_minimal()

print(p1)

# CHUNK 11: Visualization - Projects Over Time ----
cat("\n=== VIZ 2: Projects Over Time ===\n")

p2 <- project_summary %>%
  count(AllocationYear) %>%
  ggplot(aes(x = AllocationYear, y = n)) +
  geom_line(color = "darkgreen", size = 1.2) +
  geom_point(color = "darkgreen", size = 3) +
  labs(
    title = "Number of Projects by Allocation Year",
    x = "Year",
    y = "Number of Projects"
  ) +
  theme_minimal()

print(p2)

# CHUNK 12: Visualization - Beneficiaries by Gender ----
cat("\n=== VIZ 3: Beneficiaries by Gender and Age ===\n")

p3 <- beneficiary_totals %>%
  select(Total_Men, Total_Women, Total_Boys, Total_Girls) %>%
  pivot_longer(everything(), names_to = "Category", values_to = "Count") %>%
  mutate(Category = str_remove(Category, "Total_")) %>%
  ggplot(aes(x = Category, y = Count, fill = Category)) +
  geom_col() +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Beneficiaries by Gender and Age Group",
    x = "Category",
    y = "Number of Beneficiaries"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(p3)

# SUMMARY: Available Data Objects ----
cat("\n=== ANALYSIS COMPLETE ===\n")
cat("\nAvailable dataframes for further exploration:\n")
cat("  • allocation_flow -", nrow(allocation_flow), "rows\n")
cat("  • project_summary -", nrow(project_summary), "rows\n")
cat("  • project_summary_location -", nrow(project_summary_location), "rows\n")
cat("  • project_summary_cluster -", nrow(project_summary_cluster), "rows\n")
cat("  • pipeline_summary -", nrow(pipeline_summary), "rows\n")
cat("  • clusters -", nrow(clusters), "rows\n")
cat("  • contributions -", nrow(contributions), "rows\n")
cat("\nTip: Use View(dataframe_name) to explore data in a spreadsheet view\n")

# CHUNK 13: 2025 Funding by Organization ----
cat("\n=== 2025 FUNDING BY ORGANIZATION ===\n")

# Filter for 2025 projects and aggregate by organization
funding_2025 <- project_summary %>%
  filter(AllocationYear == 2025) %>%
  group_by(OrganizationName, OrganizationType) %>%
  summarise(
    Total_Funding = sum(Budget, na.rm = TRUE),
    Number_of_Projects = n(),
    .groups = 'drop'
  ) %>%
  arrange(desc(Total_Funding))

# Display top 20 organizations
cat("\nTop 20 Organizations by Funding in 2025:\n")
print(head(funding_2025, 20))

# Total 2025 funding
total_2025 <- sum(funding_2025$Total_Funding)
cat("\nTotal 2025 Funding: $", format(total_2025, big.mark = ","), "\n", sep = "")

# Visualization: Top 15 Organizations
p_2025 <- funding_2025 %>%
  head(15) %>%
  ggplot(aes(x = reorder(OrganizationName, Total_Funding), 
             y = Total_Funding / 1e6,
             fill = OrganizationType)) +
  geom_col() +
  geom_text(aes(label = paste0("$", format(round(Total_Funding / 1e6, 1), nsmall = 1), "M")),
            hjust = -0.1,
            size = 3,
            color = "black") +
  coord_flip() +
  scale_fill_brewer(palette = "Set3") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Top 15 Organizations by Funding - 2025",
    subtitle = paste("Total 2025 Funding: $", format(total_2025/1e6, digits = 1), "M"),
    x = "Organization",
    y = "Funding (Millions USD)",
    fill = "Organization Type"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    axis.text.y = element_text(size = 9)
  )

print(p_2025)

# Funding breakdown by organization type in 2025
funding_by_type_2025 <- project_summary %>%
  filter(AllocationYear == 2025) %>%
  group_by(OrganizationType) %>%
  summarise(
    Total_Funding = sum(Budget, na.rm = TRUE),
    Number_of_Orgs = n_distinct(OrganizationName),
    Number_of_Projects = n(),
    .groups = 'drop'
  ) %>%
  arrange(desc(Total_Funding))

cat("\n2025 Funding by Organization Type:\n")
print(funding_by_type_2025)

# Pie chart for organization type distribution
p_2025_type <- funding_by_type_2025 %>%
  ggplot(aes(x = "", y = Total_Funding, fill = OrganizationType)) +
  geom_col(width = 1) +
  coord_polar("y", start = 0) +
  scale_fill_brewer(palette = "Set3") +
  labs(
    title = "2025 Funding Distribution by Organization Type",
    fill = "Organization Type"
  ) +
  theme_void() +
  theme(legend.position = "right")

print(p_2025_type)

