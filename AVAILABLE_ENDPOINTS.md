# CBPF API Available Endpoints Analysis

**Research Date:** February 19, 2026  
**API Base:** https://cbpfapi.unocha.org/vo1/odata

## Currently Used in Project ✅

| Endpoint | Status | Records | Purpose |
|----------|--------|---------|---------|
| **ProjectSummary** | ✅ Used | 16,305 | Approved/implemented projects (main dataset) |
| **ProjectSummaryWithLocation** | ✅ Used | Large | Projects with geographic data |
| **PipelineProjectSummary** | ✅ Used | 581 | Projects under review/rejected |
| **PipelineProjectCluster** | ✅ Used | Medium | Cluster assignments for pipeline projects |
| **Cluster** | ✅ Used | Medium | Cluster/sector definitions |
| **Contribution** | ✅ Used | Medium | Donor contributions to funds |

## Downloaded But NOT Used 📁

| Endpoint | Status | Records | Potential Use |
|----------|--------|---------|---------------|
| **AllocationFlow** | 📁 Downloaded, not loaded | Unknown | Funding flows by partner type over time |

## Available But NOT Downloaded 🔍

### ✅ WORKING Endpoints (tested successfully):

| Endpoint | Status | Size | What It Contains |
|----------|--------|------|------------------|
| **Poolfund** | ✅ Works | 47 funds | Fund metadata (name, country, coordinates, codes) |
| **ProjectSummaryWithLocationAndCluster** | ✅ Works | Large | Combined location + cluster data (not currently used) |

### ❌ NON-FUNCTIONAL Endpoints (return 404 or 500 errors):

**High-Value Endpoints (if they worked):**
- Budget - Detailed budget breakdowns
- GmsProjectByYear - Projects aggregated by year
- Location - Geographic reference data
- LogicalFramework - Project results frameworks
- LogicalFrameworkActivity - Planned activities
- LogicalFrameworkIndicator - Performance indicators
- LogicalFrameworkOutcome - Expected outcomes
- LogicalFrameworkOutput - Project outputs
- NarrativeReportBeneficiary - Beneficiary data from reports
- NarrativeReportSummary - Narrative reporting
- PartnerDueDiligence - Partner vetting/approval status
- PartnerCA - Partnership capacity assessments
- SubGrant - Sub-granting information
- Workplan - Project work plans

**Financial/Disbursement Endpoints:**
- CostEffectiveAnalysis
- CostTracking
- DirectCosting
- DisbursementMilestone
- FinancialReportMilestone
- FinancialReportSection
- FinancialReportSummary
- FirstDisbursementMilestone

**Status/Process Tracking:**
- CBPFInstanceProcessLogs
- CBPFInstanceStatus
- CBPFPartnerScorecard
- CBPFProjectScorecard
- RevisionRequestMilestone
- SubmissionOfProposalMilestone
- TechnicalReviewMilestone

**Other Available Endpoints:**
- FocalPoint - Contact information
- NarrativeReportLogicalFramework
- NarrativeReportMilestone
- NarrativeReportMonitoring
- OtherBeneficiary
- OtherFunding
- OtherInfoOrganization
- Project - Base project entity
- ProjectAllLocationsByActivity
- ProjectLocation
- ProjectLocationActivities
- ProjectLocationLevel
- SRP - Strategic Response Plan data

## Recommendations

### 🎯 Quick Wins - Add These to Report:

1. **Poolfund** - Fund metadata
   - Download: ✅ Working (47 records)
   - Use case: Show fund details, coordinates for maps, country codes
   - Effort: Very low

2. **AllocationFlow** - Already downloaded!
   - Download: ✅ Already have it
   - Use case: Show funding flows by partner type over time
   - Effort: Low - just load it in the report

3. **ProjectSummaryWithLocationAndCluster** - Combined dataset
   - Download: ✅ Working (large dataset)
   - Use case: Richer analysis combining location + cluster
   - Effort: Low - replaces separate files

### ⚠️ Currently Broken - Cannot Use:

Almost all detailed reporting, financial tracking, and monitoring endpoints return 404 or 500 errors. These may be:
- Internal-only endpoints
- Deprecated/removed endpoints
- Restricted access endpoints
- Not yet implemented features

## Complete Endpoint List (50 total)

**Status Legend:**
- ✅ Working and tested
- 📁 Downloaded but not loaded
- ❌ Returns 404/500 error
- ⚠️ Used in project

```
✅ ⚠️ Cluster
✅ ⚠️ Contribution  
✅ ⚠️ PipelineProjectCluster
✅ ⚠️ PipelineProjectSummary
✅ ⚠️ ProjectSummary
✅ ⚠️ ProjectSummaryWithLocation
✅    Poolfund
✅    ProjectSummaryWithLocationAndCluster
📁    AllocationFlow (downloaded, not loaded)
❌    Budget
❌    CBPFInstanceProcessLogs
❌    CBPFInstanceStatus
❌    CBPFPartnerScorecard
❌    CBPFProjectScorecard
❌    CostEffectiveAnalysis
❌    CostTracking
❌    DirectCosting
❌    DisbursementMilestone
❌    FinancialReportMilestone
❌    FinancialReportSection
❌    FinancialReportSummary
❌    FirstDisbursementMilestone
❌    FocalPoint
❌    GmsProjectByYear
❌    Location
❌    LogicalFramework
❌    LogicalFrameworkActivity
❌    LogicalFrameworkIndicator
❌    LogicalFrameworkOutcome
❌    LogicalFrameworkOutput
❌    NarrativeReportBeneficiary
❌    NarrativeReportLogicalFramework
❌    NarrativeReportMilestone
❌    NarrativeReportMonitoring
❌    NarrativeReportSummary
❌    OtherBeneficiary
❌    OtherFunding
❌    OtherInfoOrganization
❌    PartnerCA
❌    PartnerDueDiligence
❌    Project
❌    ProjectAllLocationsByActivity
❌    ProjectLocation
❌    ProjectLocationActivities
❌    ProjectLocationLevel
❌    RevisionRequestMilestone
❌    SRP
❌    SubGrant
❌    SubmissionOfProposalMilestone
❌    TechnicalReviewMilestone
❌    Workplan
```

## Next Steps

### Immediate Actions:
1. ✅ **Load AllocationFlow** - Already downloaded, just add to report
2. ✅ **Download Poolfund** - Get fund metadata (47 records)
3. Consider **ProjectSummaryWithLocationAndCluster** - May simplify current multi-file approach

### Future Exploration:
- Monitor CBPF API for new endpoints or restored functionality
- Check if authentication enables access to restricted endpoints
- Contact OCHA CBPF team about broken endpoints

## Testing Commands

```bash
# Test any endpoint
curl -s "https://cbpfapi.unocha.org/vo1/odata/ENDPOINT_NAME?\$format=csv&\$top=5"

# Check endpoint size
curl -s "https://cbpfapi.unocha.org/vo1/odata/ENDPOINT_NAME?\$format=csv" | wc -l

# Get full metadata
curl -s "https://cbpfapi.unocha.org/vo1/odata/\$metadata" | grep -A 20 "EntityType.*ENDPOINT"

# List all endpoints
curl -s "https://cbpfapi.unocha.org/vo1/odata/" | grep -o '<collection href="[^"]*"'
```
