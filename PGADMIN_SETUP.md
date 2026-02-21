# CBPF Data Pipeline - Quick Setup for pgAdmin

## Step 1: Create Database in pgAdmin

⚠️ **IMPORTANT**: You'll get an error if you try to run CREATE DATABASE with other SQL commands. It MUST be run separately!

### Option A: Using pgAdmin GUI (EASIEST - Recommended)
1. Right-click "Databases" → "Create" → "Database..."
2. **Database**: `CBPF_Data`
3. **Owner**: postgres (or your user)
4. Click "Save"
5. ✅ Done! Skip to Step 2.

### Option B: Using SQL (Advanced)
1. In pgAdmin, connect to your PostgreSQL server
2. Right-click on "postgres" database → "Query Tool"
3. Paste and execute **ONLY** this command:
```sql
CREATE DATABASE "CBPF_Data";
```
4. Close that query window
5. Continue to Step 2

**Alternative**: Run the file `00_create_database_only.sql` (it contains just the CREATE DATABASE command)

## Step 2: Create All Tables

1. In pgAdmin, right-click on the new **CBPF_Data** database → "Query Tool"
2. Open the file `create_cbpf_database.sql` in a text editor
3. Copy **ALL the contents** of the file
4. Paste into the Query Tool
5. Click "Execute" (F5) or the ▶️ button

**Expected result**: 
```
Query returned successfully in X msec.
```

✅ If you see this, all tables, indexes, views, and triggers are created!

## Step 3: Verify Tables Were Created

In the Query Tool, run:
```sql
-- Check tables and views
SELECT table_name, table_type
FROM information_schema.tables 
WHERE table_schema = 'raw_data'
ORDER BY table_type, table_name;
```

You should see **10 items total**:

**8 Data Tables** (for storing raw data):
- cbpf_allocation_flow
- cbpf_cluster
- cbpf_contribution
- cbpf_pipeline_cluster
- cbpf_pipeline_summary
- cbpf_project_location
- cbpf_project_location_cluster
- cbpf_project_summary

**2 Views** (for monitoring/queries):
- cbpf_countries (list of all countries with data)
- cbpf_data_summary (summary statistics)

## Step 4: Configure n8n Workflow

### Node 1: Create Endpoint List (Code)
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

### Node 2: Split Out
- Just connect, no configuration needed

### Node 3: HTTP Request - Fetch CBPF Data
- **Method**: GET
- **URL**: `{{ $json.url }}`
- **Response Format**: String (to get raw CSV)

### Node 4: Parse CSV (Code)
- Copy the entire content from `n8n-parse-csv-for-upsert.js`

### Node 5: PostgreSQL - Insert or Update
**IMPORTANT**: Configure for each table type OR use dynamic configuration

**Operation**: Insert or Update (UPSERT)

**Table**: `raw_data.{{ $json.tableName }}`

**Columns to Match On** (varies by table - n8n will use these for the WHERE clause):
- For project_summary: `project_code, pooled_fund_name, allocation_year`
- For allocation_flow: `pooled_fund_name, allocation_source_name, allocation_year, project_code`
- etc. (see the schema file for each table's UNIQUE constraint)

**OR use this simpler approach:**
Since the unique keys vary by table, use a Switch node before PostgreSQL:
1. Add **Switch** node after Parse CSV
2. Route by `{{ $json.tableName }}`
3. Have 8 different PostgreSQL nodes, one for each table with proper unique keys configured

## Step 5: Test the Workflow

1. In n8n, click "Execute Workflow" (manual trigger)
2. Monitor each node's execution
3. Check for errors

## Step 6: Verify Data in pgAdmin

```sql
-- Check summary
SELECT * FROM raw_data.cbpf_data_summary;

-- Check countries available
SELECT * FROM raw_data.cbpf_countries ORDER BY country;

-- Sample Ukraine data
SELECT 
    project_code,
    data->>'OrganizationName' as organization,
    data->>'Budget' as budget
FROM raw_data.cbpf_project_summary
WHERE pooled_fund_name = 'Ukraine'
LIMIT 10;
```

## Daily UPSERT Behavior

With the UNIQUE constraints in place:
- **New records**: Will be inserted
- **Existing records** (matching unique keys): Will be updated
- **updated_at** column: Automatically updated by trigger
- **No duplicates**: Guaranteed by UNIQUE constraints

### Example: How Upsert Works

First run (Day 1):
```
ProjectCode: UA-2024-001 → Record inserted ✓
```

Second run (Day 2) - same project, updated budget:
```
ProjectCode: UA-2024-001 → Record UPDATED (not duplicated) ✓
updated_at: 2026-02-16 ✓
```

Third run (Day 3) - new project:
```
ProjectCode: UA-2024-002 → Record inserted ✓
ProjectCode: UA-2024-001 → Record updated ✓
```

## Monitoring & Maintenance

### Check Last Update
```sql
SELECT 
    table_name,
    total_records,
    countries,
    last_updated,
    last_fetched
FROM raw_data.cbpf_data_summary;
```

### Check for Recent Updates
```sql
SELECT 
    pooled_fund_name,
    COUNT(*) as records_updated
FROM raw_data.cbpf_project_summary
WHERE updated_at > NOW() - INTERVAL '1 day'
GROUP BY pooled_fund_name
ORDER BY records_updated DESC;
```

### Find Records Not Updated Recently (stale data)
```sql
SELECT 
    pooled_fund_name,
    COUNT(*) as stale_records
FROM raw_data.cbpf_project_summary
WHERE updated_at < NOW() - INTERVAL '7 days'
GROUP BY pooled_fund_name;
```

## Troubleshooting in pgAdmin

### Issue: "CREATE DATABASE cannot run inside a transaction block"
**Solution**: 
- Don't run CREATE DATABASE with other SQL commands
- Use pgAdmin GUI to create database (Option A in Step 1)
- Or run CREATE DATABASE alone, then close that query window and open a new one

### Issue: Tables not showing up
1. Right-click database → "Refresh"
2. Expand: CBPF_Data → Schemas → raw_data → Tables

### Issue: Permission denied
```sql
-- Grant yourself permissions
GRANT ALL ON SCHEMA raw_data TO your_username;
GRANT ALL ON ALL TABLES IN SCHEMA raw_data TO your_username;
```

### Issue: Duplicate key violations (shouldn't happen with upsert, but if it does)
```sql
-- Find duplicates
SELECT 
    project_code, 
    pooled_fund_name, 
    allocation_year, 
    COUNT(*)
FROM raw_data.cbpf_project_summary
GROUP BY project_code, pooled_fund_name, allocation_year
HAVING COUNT(*) > 1;
```

## Next Steps

1. ✅ Database created
2. ✅ Tables created with upsert support
3. ✅ n8n workflow configured
4. ✅ Test run successful
5. ⏭️ Schedule daily automatic updates
6. ⏭️ Build analysis queries for your specific use case
7. ⏭️ Connect R/Python for advanced analysis

## Files Reference

- **`create_cbpf_database.sql`** - Complete database setup (this is what you just ran)
- **`n8n-parse-csv-for-upsert.js`** - CSV parser with upsert support
- **`ukraine_analysis_queries.sql`** - Example queries (works for any country)

---

**Your database is now ready for daily upserts of CBPF data from all countries!** 🎉
