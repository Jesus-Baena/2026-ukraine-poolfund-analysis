# CBPF Data Pipeline - Complete Setup

## 📦 What You Got

I've set up a complete automated data pipeline for fetching and analyzing CBPF (Country-Based Pooled Funds) data with focus on Ukraine. Here's what's included:

### Files Created

1. **`n8n-pooled-funds-workflow.json`** - Complete n8n workflow definition
2. **`create_cbpf_tables.sql`** - PostgreSQL database schema
3. **`ukraine_analysis_queries.sql`** - Pre-built analysis queries for Ukraine
4. **`SETUP_GUIDE.md`** - Step-by-step setup instructions
5. **`WORKFLOW_APPROACHES.md`** - Different implementation strategies
6. **`n8n-csv-parser.js`** - Improved CSV parsing code
7. **`README_PIPELINE.md`** - This file

### Original Files (Kept for Reference)
- `fetch_cbpf_data.sh` - Your original bash script
- `CBPF_API_GUIDE.md` - API documentation

## 🚀 Quick Start

### 1. Set Up Database (5 minutes)
```bash
# Create database
createdb cbpf_data

# Create tables
psql -d cbpf_data -f create_cbpf_tables.sql

# Verify
psql -d cbpf_data -c "SELECT * FROM cbpf_summary;"
```

### 2. Configure n8n (10 minutes)

#### In n8n:
1. Open your "Pooled Funds Call" workflow
2. Import or manually build the workflow structure:
   ```
   Schedule Trigger ──┐
                      ├─→ Create Endpoints → Split Out → HTTP Request → 
   Manual Trigger ────┘    Parse CSV → PostgreSQL Insert → Summary
   ```

#### Configure PostgreSQL Connection:
- Host: `localhost`
- Database: `cbpf_data`
- Port: `5432`
- Username/Password: your credentials

### 3. Test Run (2 minutes)
1. Click "Execute Workflow" (manual trigger)
2. Watch nodes execute
3. Check PostgreSQL:
```sql
SELECT * FROM cbpf_summary;
```

### 4. Schedule Automatic Updates
Set Schedule Trigger to run:
- **Daily at 2 AM**: For fresh data every day
- **Weekly**: For less frequent updates
- **Custom**: Based on your needs

## 📊 Analyzing Ukraine Data

Once data is loaded, run queries from `ukraine_analysis_queries.sql`:

```sql
-- Quick overview
SELECT 
    COUNT(DISTINCT data->>'ProjectCode') as projects,
    SUM((data->>'Budget')::numeric) as total_budget_usd
FROM cbpf_project_summary
WHERE data->>'PooledFundName' = 'Ukraine';

-- Top donors
SELECT 
    data->>'ContributionSourceName' as donor,
    SUM((data->>'PaidAmt')::numeric) as total_usd
FROM cbpf_contribution
WHERE data->>'PooledFundName' = 'Ukraine'
GROUP BY donor
ORDER BY total_usd DESC;

-- Funding by sector
SELECT 
    data->>'ClusterName' as sector,
    SUM((data->>'Budget')::numeric) as budget_usd
FROM cbpf_project_location_cluster
WHERE data->>'PooledFundName' = 'Ukraine'
GROUP BY sector
ORDER BY budget_usd DESC;
```

## 🔄 How It Works

### Data Flow
```
CBPF API → n8n HTTP Request → Parse CSV → PostgreSQL → Analysis
```

### Workflow Steps
1. **Trigger**: Schedule or manual
2. **Create Endpoint List**: Prepares 8 API endpoints
3. **Split Out**: Processes each endpoint separately
4. **HTTP Request**: Fetches CSV data from CBPF API
5. **Parse CSV**: Converts CSV to JSON format
6. **PostgreSQL Insert**: Stores in appropriate table
7. **Summary**: Logs results

### Data Tables (8 total)
- `cbpf_project_summary` - Core project information
- `cbpf_allocation_flow` - Allocation details
- `cbpf_contribution` - Donor contributions
- `cbpf_cluster` - Sectoral clusters
- `cbpf_pipeline_summary` - Pipeline projects
- `cbpf_pipeline_cluster` - Pipeline by cluster
- `cbpf_project_location` - Geographic distribution
- `cbpf_project_location_cluster` - Combined location+cluster

## 🎯 Use Cases

### For Ukraine Analysis
1. **Total funding received**
2. **Top donor countries**
3. **Funding by humanitarian sector**
4. **Geographic distribution (oblasts)**
5. **Active implementing organizations**
6. **Project status tracking**
7. **Trends over time**

### Integration with Your R Analysis
```r
# In your R script
library(RPostgreSQL)

con <- dbConnect(PostgreSQL(),
                 dbname = "cbpf_data",
                 host = "localhost",
                 user = "your_user",
                 password = "your_password")

# Fetch Ukraine projects
ukraine_data <- dbGetQuery(con, "
  SELECT 
    data->>'ProjectCode' as project_code,
    data->>'OrganizationName' as organization,
    (data->>'Budget')::numeric as budget,
    data->>'ClusterName' as cluster
  FROM cbpf_project_location_cluster
  WHERE data->>'PooledFundName' = 'Ukraine'
")

# Continue your analysis in R...
```

## 📈 Maintenance

### Daily
- Check n8n execution logs
- Verify data freshness: `SELECT MAX(fetched_at) FROM cbpf_project_summary;`

### Weekly
- Review record counts: `SELECT * FROM cbpf_summary;`
- Check for anomalies in data

### Monthly
- Backup database
- Review and optimize slow queries
- Update analysis queries as needed

## 🛠️ Troubleshooting

### Problem: No data in tables
**Solution**: 
1. Check n8n workflow execution history
2. Verify CBPF API is accessible
3. Check PostgreSQL connection

### Problem: Workflow times out
**Solution**:
- Increase HTTP Request timeout to 60000ms
- Process endpoints one at a time (remove parallel processing)

### Problem: CSV parsing errors
**Solution**:
- Use improved parser from `n8n-csv-parser.js`
- Check API response format hasn't changed

## 📚 Documentation

- **SETUP_GUIDE.md** - Detailed setup instructions
- **WORKFLOW_APPROACHES.md** - Alternative implementations
- **ukraine_analysis_queries.sql** - Ready-to-use SQL queries
- **CBPF_API_GUIDE.md** - API documentation

## 🔐 Security Notes

1. **PostgreSQL credentials**: Store in n8n credentials manager, never in workflow
2. **Database access**: Limit to localhost or use SSL
3. **API keys**: CBPF API is public, but verify if you need authentication
4. **Backups**: Regular backups recommended before truncate operations

## 🚦 Next Steps

### Immediate
- [ ] Run database setup script
- [ ] Configure n8n workflow
- [ ] Test with manual trigger
- [ ] Verify data in PostgreSQL

### Short Term
- [ ] Schedule automatic runs
- [ ] Create visualizations (Metabase, Superset, R Shiny)
- [ ] Set up monitoring/alerts
- [ ] Document your specific analysis needs

### Long Term
- [ ] Add incremental update logic
- [ ] Implement data versioning
- [ ] Create API for your analysis results
- [ ] Automate report generation

## 💡 Tips

1. **Start Simple**: Use the batch truncate approach first
2. **Test Thoroughly**: Run manually before scheduling
3. **Monitor Closely**: Check executions for first few days
4. **Iterate**: Refine based on actual usage patterns
5. **Document Changes**: Keep notes on customizations

## 🤝 Support Resources

- **CBPF API**: https://cbpfapi.unocha.org/
- **n8n Docs**: https://docs.n8n.io/
- **PostgreSQL**: https://www.postgresql.org/docs/
- **R + PostgreSQL**: https://rpostgres.r-dbi.org/

## 📊 Expected Results

After successful setup and first run:
- ~8 tables populated with CBPF data
- Thousands of project records
- Ready for R/Python analysis
- Updated automatically on schedule

## ✅ Success Criteria

You're all set when:
- [ ] All 8 tables have data
- [ ] `cbpf_summary` view shows record counts
- [ ] Sample queries return results
- [ ] Workflow runs without errors
- [ ] You can query Ukraine-specific data
- [ ] Schedule trigger works automatically

---

**Ready to analyze Ukraine humanitarian funding!** 🇺🇦

For questions or issues, refer to SETUP_GUIDE.md or check n8n execution logs.
