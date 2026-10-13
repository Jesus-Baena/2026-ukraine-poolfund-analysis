#!/usr/bin/env bash
# Build (if missing or older than the data) and serve the explorer with Datasette.
#   tools/explorer/explore.sh            # build if needed, serve on :8001, open browser
#   tools/explorer/explore.sh --rebuild  # force rebuild
#   tools/explorer/explore.sh --no-browser
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DB="$ROOT/explorer/cbpf-explorer.sqlite"
PORT="${PORT:-8001}"
OPEN="-o"
for a in "$@"; do case "$a" in --rebuild) rm -f "$DB";; --no-browser) OPEN="";; esac; done
if [ ! -f "$DB" ] || [ -n "$(find "$ROOT/Raw-data" -newer "$DB" \( -name '*.csv' -o -name '*.json.gz' \) -print -quit)" ]; then
  python3 "$ROOT/tools/explorer/build_db.py" --out "$DB"
fi
exec uvx datasette "$DB" -m "$ROOT/explorer/metadata.json" -p "$PORT" $OPEN --static static:"$ROOT/explorer/static" \
  --setting truncate_cells_html 400 \
  --setting sql_time_limit_ms 30000 --setting max_returned_rows 10000 --setting facet_time_limit_ms 5000 \
  --setting default_page_size 50 --setting allow_download on
