#!/usr/bin/env bash
# Pull the newest complete archive day (vo1 + vo2) and the most recent weekly
# LogicalFrameworkIndicator file from the swarm into Raw-data/archive/<day>/.
# Raw-data/archive/ is gitignored (≈40 MB per day).
set -euo pipefail
HOST="${CBPF_ARCHIVE_HOST:-chernihiv}"
REMOTE="/mnt/swarm-data/archive/cbpf"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DAY="${1:-$(ssh "$HOST" "ls $REMOTE | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' | while read d; do [ -f $REMOTE/\$d/.complete ] && echo \$d; done | tail -1")}"
echo "Syncing $DAY from $HOST"
mkdir -p "$ROOT/Raw-data/archive/$DAY"
rsync -az --exclude '.complete' "$HOST:$REMOTE/$DAY/" "$ROOT/Raw-data/archive/$DAY/"
LFI="$(ssh "$HOST" "ls -t $REMOTE/*/LogicalFrameworkIndicator.json.gz 2>/dev/null | head -1")"
if [ -n "$LFI" ] && [ ! -f "$ROOT/Raw-data/archive/$DAY/LogicalFrameworkIndicator.json.gz" ]; then
  echo "Adding weekly logframe file from $LFI"
  rsync -az "$HOST:$LFI" "$ROOT/Raw-data/archive/$DAY/LogicalFrameworkIndicator.json.gz"
fi
du -sh "$ROOT/Raw-data/archive/$DAY"
