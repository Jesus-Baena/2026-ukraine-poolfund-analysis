# CBPF API Data Availability - Research Findings

> **Update, 6 October 2026** — see the dated section at the end of this file. Headlines: a second API version (`vo2`) with 24 working endpoints exists; `LogicalFrameworkIndicator` (vo1) works again; `AllocationFlow` is still dead; the `poolfundAbbrv=UKR` filter no longer works on any vo1 endpoint; data is now archived daily by the swarm `harvest` stack instead of fetched by hand.

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


---

## Update: endpoint sweep of 6 October 2026

Every collection declared by the vo1 service document (50) and the vo2 service document (28) was requested with `$top=5&$format=json`. Results, with the February 2026 status for comparison:

### vo1 (`https://cbpfapi.unocha.org/vo1/odata`)

| Status | Endpoints |
|---|---|
| **200, data** | ProjectSummary, ProjectSummaryWithLocation, ProjectSummaryWithLocationAndCluster, PipelineProjectSummary, PipelineProjectCluster, Cluster, Contribution, Poolfund, **LogicalFrameworkIndicator (new: 212,351 rows, ~113 MB raw)** |
| 200, always empty `[]` | CBPFInstanceProcessLogs, DirectCosting |
| 404 | Budget, CBPFInstanceStatus, CBPFPartnerScorecard, CBPFProjectScorecard, FinancialReportSection, FinancialReportSummary, FocalPoint, GmsProjectByYear, Location, LogicalFramework, LogicalFrameworkActivity, LogicalFrameworkOutcome, LogicalFrameworkOutput, NarrativeReportLogicalFramework, NarrativeReportMonitoring, NarrativeReportSummary, OtherBeneficiary, OtherFunding, OtherInfoOrganization, PartnerCA, PartnerDueDiligence, Project, ProjectAllLocationsByActivity, ProjectLocation, ProjectLocationActivities, ProjectLocationLevel, SRP, SubGrant, Workplan, AllocationFlow (was 500 in Feb) |
| 501 Not Implemented | CostEffectiveAnalysis, CostTracking, DisbursementMilestone, FinancialReportMilestone, FirstDisbursementMilestone, NarrativeReportMilestone, RevisionRequestMilestone, SubmissionOfProposalMilestone, TechnicalReviewMilestone |
| timeout / empty | NarrativeReportBeneficiary |

The `poolfundAbbrv=UKR` query parameter documented in `CBPF_API_GUIDE.md` returns an empty `value` array on every vo1 endpoint (it only works on `Poolfund`, where it is ignored). Fetch all funds and filter on `PooledFundName`.

### vo2 (`https://cbpfapi.unocha.org/vo2/odata`) — previously unknown

| Status | Endpoints | Notes |
|---|---|---|
| **200, data** | Poolfund, MstPooledFund, MstClusters, MstOrgType, MstAllocationSource, MstPFAdminLocationType, DonorMaster, SubIPType, GenderMarker | reference / master tables |
| **200, data** | **AllocationTypes** (931 rows) | one row per allocation round, CBPF *and CERF*: planned USD, planned start/end, HC last approval date, projects approved / under approval with budgets, HRP plan, and `Documents` (strategy papers, `##`/`|||`-delimited) |
| **200, data** | **ExtendedAllocationDetails** (257) | allocation-level themes, target amounts, targeted people by group |
| **200, data** | **AllocationFlowByOrgType** (1,840) | fund → org-type flows by year; the working replacement for vo1 `AllocationFlow` |
| **200, data** | AllocationCountByYearAndFund (267), AllocationBudgetTotalsByYearAndFund (805) | official approved/pipeline counts and budgets, reserve vs standard split per org type |
| **200, data** | ContributionTotal (3,138), HFUManagementCost (945), PoolFundBeneficiarySummary (5,866), ProjectGAMSummary, ProjectSummaryBeneficiaryDetail | |
| **200, data** | ProjectSummary, ProjectSummaryV2, ProjectSummaryAggV2, PipelineProjectSummary | vo1-like project tables with different field sets (V2 uses abbreviated column names) |
| **200, data** | **LastModified** | `{"last_updated_date": "2026-10-06T01:02:38"}` — the API's own refresh stamp |
| 500 | NarrativeReportLogicalFramework | |
| 404 | LocationMaster, HRPCBPFFundingSummary | |
| 400 | CBPFSummary | needs parameters (undocumented) |

Row counts are as fetched on 6 October 2026. Full pulls of the small vo2 endpoints are in `Raw-data/vo2/`.

### What is now collected automatically

The swarm `harvest` stack (`2025-swarm-infrastructure-deployment/harvest/cbpf-snapshot.sh`, config `harvest_cbpf_snapshot_v2`) archives, every day at 04:00 UTC:

- vo1: the 8 working endpoints + Poolfund (required), AllocationFlow (optional, still dead), LogicalFrameworkIndicator (weekly, Sundays);
- vo2: the 20 small working endpoints (required) and the 4 large project tables (optional);
- a `manifest.txt` with row counts and a `.complete` marker; the 7 core vo1 tables are also loaded into Postgres `CBPF.raw_data`.

Vintages exist since 29 August 2026 (vo1) and from the v2 deployment onwards (vo2).
