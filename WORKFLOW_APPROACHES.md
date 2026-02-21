# Alternative n8n Workflow Approaches for CBPF Data

## Approach 1: Direct Table Insert (Recommended for Simplicity)

### Pros:
- Simpler configuration
- Better error handling per record
- Can see which records fail
- Native n8n PostgreSQL operations

### Workflow Structure:
```
Trigger → Create Endpoints → Split Out → HTTP Request → Parse CSV → 
Split Out (records) → PostgreSQL Insert → Aggregate Results
```

### PostgreSQL Node Configuration:
- **Operation**: Insert
- **Table**: `{{ $json.tableName }}`
- **Columns to Match On**: Leave empty (for fresh insert)
- **Column Values**:
  - `data`: `{{ JSON.stringify($json.data) }}`
  - `fetched_at`: `{{ $json.fetchedAt }}`

This inserts each record separately but allows for better error handling.

---

## Approach 2: Batch Insert with Truncate (Current)

### Pros:
- Faster for large datasets
- Ensures fresh data on each run
- Single transaction per table

### Cons:
- Loses historical data
- All-or-nothing for each table
- More complex SQL

### PostgreSQL Node Configuration:
- **Operation**: Execute Query
- **Query**: See the full workflow JSON for the truncate + batch insert query

---

## Approach 3: Upsert Strategy (Best for Incremental Updates)

### Pros:
- Keeps historical versions
- Only updates changed records
- More efficient for frequent updates

### Cons:
- Requires unique key identification
- More complex schema

### Modified Schema:
```sql
ALTER TABLE cbpf_project_summary
ADD COLUMN project_code VARCHAR(50) UNIQUE,
ADD COLUMN last_modified TIMESTAMP;
```

### PostgreSQL Node Configuration:
- **Operation**: Insert or Update
- **Table**: `{{ $json.tableName }}`
- **Columns to Match On**: `project_code` (or other unique field)
- This will update existing records or insert new ones

---

## Approach 4: Staging Tables (Enterprise)

### Workflow:
```
Fetch → Load to Staging → Validate → Transform → Load to Production
```

### Schema:
```sql
CREATE TABLE cbpf_staging_project_summary (LIKE cbpf_project_summary);
```

### Process:
1. Load all data to staging table
2. Run validation queries
3. If valid, swap or merge to production
4. Archive old data

---

## Comparison Matrix

| Approach | Speed | Complexity | History | Reliability |
|----------|-------|------------|---------|-------------|
| Direct Insert | Medium | Low | Yes | High |
| Batch Truncate | Fast | Medium | No | Medium |
| Upsert | Fast | High | Yes | High |
| Staging | Slow | High | Yes | Very High |

---

## Recommendation

**For your Ukraine analysis project:**

Use **Approach 2 (Batch Truncate)** because:
1. CBPF data is relatively stable (updated daily/weekly)
2. You want complete snapshots, not incremental changes
3. Simpler to understand and maintain
4. Faster for your dataset size

**If you need history tracking later:**
- Add a `data_version` or `snapshot_date` column
- Keep previous versions before truncating
- Or switch to Approach 3 (Upsert)

---

## Implementation Tips

### Better CSV Parsing (handles quoted fields with commas):

```javascript
function parseCSV(csv) {
  const lines = csv.trim().split('\n');
  const headers = parseCSVLine(lines[0]);
  
  return lines.slice(1).map(line => {
    const values = parseCSVLine(line);
    const obj = {};
    headers.forEach((header, i) => {
      obj[header] = values[i] || null;
    });
    return obj;
  });
}

function parseCSVLine(line) {
  const result = [];
  let current = '';
  let inQuotes = false;
  
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    
    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      result.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }
  result.push(current.trim());
  
  return result.map(v => v.replace(/^"|"$/g, ''));
}
```

### Error Handling:

Add an "If" node after Parse CSV:
```javascript
// Condition: $json.records.length > 0
// True: Continue to PostgreSQL
// False: Log error
```

### Parallel Processing:

Since Split Out processes sequentially, consider:
- Setting "Split in Batches" to process multiple endpoints simultaneously
- Or use 8 separate HTTP Request → Parse → Insert chains

---

## Next Enhancements

1. **Add retry logic** for failed API calls
2. **Implement rate limiting** to respect API limits
3. **Add data validation** before inserting
4. **Create materialized views** for common queries
5. **Set up monitoring** with n8n webhooks to Slack/email
6. **Add data quality checks** (null values, ranges, etc.)

---

## Testing Checklist

- [ ] PostgreSQL connection works
- [ ] Can fetch from all 8 endpoints
- [ ] CSV parsing handles all data formats
- [ ] Tables are created with correct schema
- [ ] Data appears in tables after insert
- [ ] Schedule trigger works
- [ ] Error handling catches failures
- [ ] Summary shows correct counts
- [ ] Can query data successfully
- [ ] Workflow completes in reasonable time

---

## Performance Benchmarks

Expected timing for initial load:
- Fetch all endpoints: ~30-60 seconds
- Parse CSV: ~5-10 seconds per endpoint
- Insert to PostgreSQL: ~10-30 seconds per endpoint
- **Total**: 3-8 minutes for complete refresh

Optimize by:
- Using batch inserts (current approach)
- Enabling PostgreSQL connection pooling
- Running during off-peak hours
- Increasing n8n worker threads (if self-hosted)
