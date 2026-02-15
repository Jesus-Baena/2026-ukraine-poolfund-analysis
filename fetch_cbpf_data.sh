#!/bin/bash
# Script to fetch CBPF data for all countries using curl
# Created: February 13, 2026

# Base API URL
BASE_URL="https://cbpfapi.unocha.org/vo1/odata"

# Output directory
OUTPUT_DIR="Raw-data"
mkdir -p "$OUTPUT_DIR"

# Timestamp for file naming
TIMESTAMP=$(date -u +"%Y%m%d_%H%M%S_UTC")

# List of endpoints
endpoints=(
    "ProjectSummary"
    "AllocationFlow"
    "Contribution"
    "Cluster"
    "PipelineProjectSummary"
    "PipelineProjectCluster"
    "ProjectSummaryWithLocation"
    "ProjectSummaryWithLocationAndCluster"
)

echo "=============================================================="
echo "  CBPF Data Fetcher - All Countries"
echo "=============================================================="
echo ""
echo "Fetching data from CBPF API..."
echo ""

# Counter for successful downloads
SUCCESS=0
TOTAL=${#endpoints[@]}

# Fetch each endpoint
for endpoint in "${endpoints[@]}"; do
    echo "Fetching $endpoint..."
    
    # Build URL (no poolfundAbbrv parameter = all countries)
    URL="${BASE_URL}/${endpoint}?\$format=csv"
    OUTPUT_FILE="${OUTPUT_DIR}/${endpoint}_ALL_${TIMESTAMP}.csv"
    
    # Download with curl
    if curl -s -o "$OUTPUT_FILE" "$URL"; then
        # Count rows (excluding header)
        ROW_COUNT=$(($(wc -l < "$OUTPUT_FILE") - 1))
        echo "  ✓ Saved: $(basename "$OUTPUT_FILE") ($ROW_COUNT rows)"
        ((SUCCESS++))
    else
        echo "  ✗ Failed to download $endpoint"
        rm -f "$OUTPUT_FILE"
    fi
done

echo ""
echo "=============================================================="
echo "Summary: $SUCCESS/$TOTAL endpoints fetched successfully"
echo "=============================================================="
echo ""
echo "Files saved in: $OUTPUT_DIR"
ls -1 "$OUTPUT_DIR"/*"$TIMESTAMP"* 2>/dev/null | while read file; do
    echo "  - $(basename "$file")"
done
