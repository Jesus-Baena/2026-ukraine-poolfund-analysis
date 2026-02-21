# Quick Fix for "CREATE DATABASE cannot run inside a transaction block"

## The Problem
PostgreSQL doesn't allow CREATE DATABASE to run inside a transaction block, but pgAdmin automatically wraps queries in transactions.

## The Solution (Choose One)

### ✅ Option 1: Use pgAdmin GUI (EASIEST)
1. In pgAdmin, right-click "Databases"
2. Select "Create" → "Database..."
3. Name: `CBPF_Data`
4. Click "Save"
5. Done! Now run `create_cbpf_database.sql` on the new database

### Option 2: Create Database Separately
1. Open Query Tool connected to "postgres" database
2. Run **ONLY** this:
   ```sql
   CREATE DATABASE "CBPF_Data";
   ```
3. Close that query window
4. Open new Query Tool connected to "CBPF_Data"
5. Run the full `create_cbpf_database.sql` script

### Option 3: Use the Separate File
1. Run `00_create_database_only.sql` first (by itself)
2. Then run `create_cbpf_database.sql`

## What Changed
- Removed CREATE DATABASE from `create_cbpf_database.sql`
- Created `00_create_database_only.sql` for just the database creation
- Updated instructions in PGADMIN_SETUP.md

## Next Steps
Once database is created:
1. Connect to CBPF_Data in pgAdmin
2. Run `create_cbpf_database.sql`
3. Verify with: `SELECT * FROM raw_data.cbpf_data_summary;`
