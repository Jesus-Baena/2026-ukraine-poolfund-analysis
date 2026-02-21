# CBPF API Data Availability - Research Findings

**Date:** February 19, 2026  
**Research Question:** Can we retrieve more complete rejected/cancelled project data?

## Summary

The PipelineProjectSummary endpoint **already contains all available pipeline data**, including rejected, cancelled, and pending projects. However, the API only retains pipeline records for **specific years** (2013-2015, 2022, 2025-2026), not comprehensive historical data.

## What We Found

### 1. Available API Endpoints

The CBPF OData API provides **50+ endpoints**, including:

**Main Data Sources:**
- `ProjectSummary` - Approved/implemented projects (16,305 records, 2010-2025)
- `PipelineProjectSummary` - Projects under review, rejected, or pending (581 records, sparse years)
- `PipelineProjectCluster` - Cluster assignments for pipeline projects
- `Contribution` - Donor contributions
- `Cluster` - Cluster/sector information

**Status/Tracking Endpoints** (currently non-functional):
- `CBPFInstanceStatus` - Returns HTTP 500 error
- `CBPFProjectScorecard` - Returns HTTP 500 error
- `Project` - Returns HTTP 500 error

### 2. PipelineProjectSummary Data Coverage

**Current Dataset (downloaded Feb 19, 2026):**
- Total records: 581
- Years available: 2013, 2014, 2015, 2022, 2025, 2026
- File: `PipelineProjectSummary_ALL_20260219_125012_UTC.csv`

**By Status Category:**
- **Rejected/Cancelled:** 123 projects
  - 8 "Project Cancelled"
  - 115 "Archived"
- **Moved to Approval System:** 174 projects
  - "Migrated in GMS" (Grant Management System)
- **Pending Approval:** Various stages
  - 42 "TR Draft" (Technical Review Draft)
  - 41 "MoU Clearance"
  - 14 "MoU Draft"
  - Others in review stages

### 3. Why Data is Sparse

The pipeline dataset is **intentionally limited** because:

1. **Purpose:** Tracks projects currently or recently in the approval pipeline
2. **Retention:** API only keeps pipeline records for active allocation rounds
3. **Lifecycle:** Once approved, projects move to `ProjectSummary` endpoint
4. **System migration:** Many older records marked as "Migrated in GMS"

### 4. OData Query Capabilities

**Working Filters:**
```bash
# Filter by year (returns 189 records for 2025)
https://cbpfapi.unocha.org/vo1/odata/PipelineProjectSummary?$filter=AllocationYear eq 2025&$format=csv

# Order by year descending
https://cbpfapi.unocha.org/vo1/odata/PipelineProjectSummary?$orderby=AllocationYear desc&$format=csv

# Select specific columns
https://cbpfapi.unocha.org/vo1/odata/PipelineProjectSummary?$select=ChfProjectCode,ProjectStatus,AllocationYear&$format=csv
```

**Not Working:**
```bash
# Filter by status - returns 0 results (syntax may be incorrect)
https://cbpfapi.unocha.org/vo1/odata/PipelineProjectSummary?$filter=ProjectStatus eq 'Project Cancelled'&$format=csv
```

### 5. Available Fields in PipelineProjectSummary

According to the OData metadata:
- PooledFundName, PooledFundId
- ChfProjectCode, ExternalProjectCode
- AllocationType, AllocationYear
- AllocationSourceID, AllocationSourceName
- OrganizationName, OrganizationType
- ProjectDuration, Budget
- TotalDirectCost, TotalSupportCost
- DateSubmitted, GenderMarker
- ActualStartDate, ActualEndDate
- **ProjectStatus, ProjectStatusId, ProjectStatusCode**
- **ProcessStatus, ProcessStatusId**
- PartnerCode

## Conclusions

### ✅ What We Have

1. **All available pipeline data** - The current download captures everything the API provides
2. **Rejection data for specific years** - 123 cancelled/archived projects from 2013-2015, 2022, 2025
3. **Working OData filters** - Can query by year, organization, allocation type
4. **Complete approved project data** - 16,305 records spanning 2010-2025

### ❌ What's Not Available

1. **Historical pipeline data** - No way to get rejected projects from 2016-2021, 2023-2024
2. **Complete rejection records** - API doesn't retain all submission/rejection history
3. **Detailed rejection reasons** - Only status codes, not explanatory text
4. **Status tracking endpoints** - Several related endpoints return errors

### 📊 Recommendation for Analysis

**Use what we have strategically:**

1. **For recent years (2022-2025):**
   - Calculate approval rates using pipeline data
   - Show rejection breakdown by status
   - Compare submissions vs approvals

2. **For all years (2010-2025):**
   - Focus on approved projects from ProjectSummary
   - Analyze funding trends, organizations, clusters
   - Track implementation and completion rates

3. **Add caveats to report:**
   - Note that pipeline data is sparse
   - Explain that rejection data only available for specific years
   - Clarify that approval rates are partial, not comprehensive

## Data Sources

- **HDX Dataset:** https://data.humdata.org/dataset/cbpf-allocations-and-contributions
- **API Base URL:** https://cbpfapi.unocha.org/vo1/odata
- **API Metadata:** https://cbpfapi.unocha.org/vo1/odata/$metadata
- **Visualization Examples:** https://cbpfgms.github.io/

## Technical Notes

- API uses OData v3 protocol
- Returns data in CSV, JSON, or XML format
- Some endpoints currently return HTTP 500 errors
- Filter syntax for string comparisons may be limited
- Large datasets download successfully without pagination
