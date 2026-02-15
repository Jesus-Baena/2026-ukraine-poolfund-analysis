# CBPF Data Fetcher

Two scripts are available to fetch data for **all countries** from the UNOCHA CBPF API:

## Option 1: Bash Script (Recommended)

```bash
./fetch_cbpf_data.sh
```

**Requirements:** curl (pre-installed on most systems)

## Option 2: R Script

```bash
Rscript fetch_cbpf_data.R
```

**Requirements:** R packages `httr` and `readr`

To install required packages:
```r
install.packages(c("httr", "readr"))
```

## What Gets Downloaded

Both scripts fetch data for **all pooled funds** from these endpoints:

1. `ProjectSummary` - Project details, budgets, beneficiaries
2. `AllocationFlow` - Funding flows by partner type
3. `Contribution` - Donor contributions
4. `Cluster` - Cluster/sector information
5. `PipelineProjectSummary` - Pipeline projects
6. `PipelineProjectCluster` - Pipeline project clusters
7. `ProjectSummaryWithLocation` - Projects with location data
8. `ProjectSummaryWithLocationAndCluster` - Projects with location and cluster data

## Output

Files are saved to `Raw-data/` with naming pattern:
```
{Endpoint}_ALL_{timestamp}.csv
```

Example:
```
ProjectSummary_ALL_20260213_153045_UTC.csv
AllocationFlow_ALL_20260213_153045_UTC.csv
```

## API Endpoint Reference

**Base URL:** `https://cbpfapi.unocha.org/vo1/odata`

**Get all countries:**
```
https://cbpfapi.unocha.org/vo1/odata/ProjectSummary?$format=csv
```

**Get specific country (e.g., Ukraine):**
```
https://cbpfapi.unocha.org/vo1/odata/ProjectSummary?poolfundAbbrv=UKR&$format=csv
```

**Available pooled fund codes:**
- `UKR` - Ukraine
- `DRC` - Democratic Republic of Congo
- `SSD` - South Sudan
- `SOM` - Somalia
- `AFG` - Afghanistan
- `SDN` - Sudan
- `SYR` - Syria
- `YEM` - Yemen
- `CAR` - Central African Republic
- And more...

## OData Query Options

Add these parameters to filter/customize data:

- `$filter` - Filter results (e.g., `AllocationYear eq 2025`)
- `$select` - Select specific columns (e.g., `Budget,OrganizationName`)
- `$top` - Limit number of results (e.g., `$top=100`)
- `$orderby` - Sort results (e.g., `$orderby=Budget desc`)
- `$format` - Output format (`csv`, `json`, `xml`)

**Example with filters:**
```
https://cbpfapi.unocha.org/vo1/odata/ProjectSummary?$filter=AllocationYear eq 2025&$format=csv
```
