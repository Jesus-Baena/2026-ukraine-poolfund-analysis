# CBPF Data Pipeline Setup Guide

## Overview
This guide helps you set up an automated data pipeline to fetch CBPF (Country-Based Pooled Funds) data from UNOCHA API and store it in PostgreSQL using n8n.

## Workflow Structure
```
Schedule Trigger ──┐
                   ├──> Create Endpoint List ──> Split Out ──> Fetch CBPF Data ──> Parse CSV ──> Insert to PostgreSQL ──> Summary
Manual Trigger ────┘
```

## Setup Steps

### 1. Create PostgreSQL Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE cbpf_data;

# Connect to the new database
\c cbpf_data

# Run the schema creation script
\i create_cbpf_tables.sql
```

Or run directly:
```bash
psql -U postgres -d cbpf_data -f create_cbpf_tables.sql
```

### 2. Set Up n8n Workflow

#### Option A: Import JSON (Recommended)
1. Open n8n web interface
2. Click "Add workflow" → "Import from File"
3. Select `n8n-pooled-funds-workflow.json`
4. Configure PostgreSQL credentials (see step 3)

#### Option B: Manual Setup
1. Open your existing "Pooled Funds Call" workflow in n8n
2. Add nodes according to the workflow structure above
3. Configure each node as detailed below

### 3. Configure PostgreSQL Connection

In n8n:
1. Go to **Settings** → **Credentials** → **New**
2. Select **PostgreSQL**
3. Enter your database details:
   - **Host**: `localhost` (or your database host)
   - **Database**: `cbpf_data`
   - **User**: your PostgreSQL username
   - **Password**: your PostgreSQL password
   - **Port**: `5432` (default)
4. Test connection and save

### 4. Update Workflow Nodes

#### Node 1: Create Endpoint List (Code)
```javascript
const endpoints = [
    { endpoint: "ProjectSummary", table: "cbpf_project_summary" },
    { endpoint: "AllocationFlow", table: "cbpf_allocation_flow" },
    { endpoint: "Contribution", table: "cbpf_contribution" },
    { endpoint: "Cluster", table: "cbpf_cluster" },
    { endpoint: "PipelineProjectSummary", table: "cbpf_pipeline_summary" },
    { endpoint: "PipelineProjectCluster", table: "cbpf_pipeline_cluster" },
    { endpoint: "ProjectSummaryWithLocation", table: "cbpf_project_location" },
    { endpoint: "ProjectSummaryWithLocationAndCluster", table: "cbpf_project_location_cluster" }
];

const baseUrl = "https://cbpfapi.unocha.org/vo1/odata";
const timestamp = new Date().toISOString();

return endpoints.map(item => ({
    json: {
        endpoint: item.endpoint,
        tableName: item.table,
        url: `${baseUrl}/${item.endpoint}?$format=csv`,
        fetchedAt: timestamp
    }
}));
```

#### Node 2: Split Out
- No configuration needed
- Just connect from "Create Endpoint List"

#### Node 3: Fetch CBPF Data (HTTP Request)
- **Method**: GET
- **URL**: `{{ $json.url }}`
- **Response Format**: String
- **Timeout**: 30000ms

#### Node 4: Parse CSV (Code)
See the workflow JSON for the complete parsing code.

#### Node 5: Insert to PostgreSQL
- **Operation**: Insert
- **Table**: Use expression `{{ $json.tableName }}`
- **Columns**: Map from parsed CSV data

#### Node 6: Summary (Code)
Aggregates results and logs summary.

### 5. Configure Schedule Trigger

Set up automatic fetching:
- **Daily**: At 2 AM UTC
- **Weekly**: Every Monday
- **Custom**: As per your requirements

In n8n Schedule Trigger node:
- **Trigger Interval**: `Days`
- **Days Between Triggers**: `1`
- **Hour**: `2`
- **Minute**: `0`

### 6. Test the Workflow

1. Click "Execute Workflow" (manual trigger)
2. Watch each node execute
3. Check for errors
4. Verify data in PostgreSQL:

```sql
-- Check record counts
SELECT * FROM cbpf_summary;

-- View Ukraine data
SELECT 
    data->>'ProjectCode' as project_code,
    data->>'OrganizationName' as organization,
    (data->>'Budget')::numeric as budget
FROM cbpf_project_location_cluster
WHERE data->>'PooledFundName' = 'Ukraine'
LIMIT 10;
```

## Querying the Data

### Example Queries

```sql
-- Total funding by country
SELECT 
    data->>'PooledFundName' as country,
    SUM((data->>'Budget')::numeric) as total_budget,
    COUNT(*) as project_count
FROM cbpf_project_summary
GROUP BY data->>'PooledFundName'
ORDER BY total_budget DESC;

-- Ukraine contributions by donor
SELECT 
    data->>'ContributionSourceName' as donor,
    SUM((data->>'PaidAmt')::numeric) as total_contribution
FROM cbpf_contribution
WHERE data->>'PooledFundName' = 'Ukraine'
GROUP BY data->>'ContributionSourceName'
ORDER BY total_contribution DESC;

-- Projects by cluster in Ukraine
SELECT 
    data->>'ClusterName' as cluster,
    COUNT(DISTINCT data->>'ProjectCode') as project_count,
    SUM((data->>'Budget')::numeric) as total_budget
FROM cbpf_project_location_cluster
WHERE data->>'PooledFundName' = 'Ukraine'
GROUP BY cluster
ORDER BY total_budget DESC;
```

## Monitoring

### Check Last Update
```sql
SELECT * FROM cbpf_summary;
```

### Workflow Execution History
Check n8n's execution history in the UI to see:
- When last run
- Success/failure status
- Number of records processed
- Any errors

## Troubleshooting

### Issue: Connection timeout
- Increase timeout in HTTP Request node
- Check internet connectivity
- Verify CBPF API is accessible

### Issue: CSV parsing errors
- Check CSV format from API
- Handle special characters in parsing code
- Add error handling

### Issue: PostgreSQL insert fails
- Check table exists: `\dt cbpf_*`
- Verify credentials
- Check data types match schema

### Issue: Duplicate records
- Current setup truncates tables on each run
- For incremental updates, modify to use UPSERT with unique keys

## Next Steps

1. **Add Error Notifications**: Configure n8n to send email/Slack on failures
2. **Incremental Updates**: Modify to only fetch new/changed records
3. **Data Validation**: Add checks for data quality
4. **Backups**: Set up regular PostgreSQL backups
5. **Analytics**: Connect to Metabase, Superset, or similar for visualization

## Files Reference

- `n8n-pooled-funds-workflow.json` - n8n workflow definition
- `create_cbpf_tables.sql` - PostgreSQL schema
- `fetch_cbpf_data.sh` - Original bash script (kept for reference)
- `CBPF_API_GUIDE.md` - API documentation

## Support

For issues with:
- **CBPF API**: https://cbpfapi.unocha.org/
- **n8n**: https://docs.n8n.io/
- **PostgreSQL**: https://www.postgresql.org/docs/
