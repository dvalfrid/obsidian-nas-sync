#!/bin/bash
# =============================================================
# scripts/compact-databases.sh
# Compacts CouchDB databases to free up disk space.
# CouchDB keeps every revision — compaction clears out old ones.
# Run e.g. monthly via cron.
# =============================================================

# =============================================================
# CUSTOMIZE HERE — list all your CouchDB databases
# =============================================================
DATABASES=("vault-alice" "vault-bob" "vault-shared")
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../config/.env"

source "$ENV_FILE"

BASE="http://localhost:5984"

# Credentials in a temp file — not visible in the process list (ps aux)
CURL_CONFIG=$(mktemp /tmp/curlrc-XXXXXX)
echo "user = \"${COUCHDB_ADMIN_USER}:${COUCHDB_ADMIN_PASSWORD}\"" > "$CURL_CONFIG"
chmod 600 "$CURL_CONFIG"
trap "rm -f $CURL_CONFIG" EXIT

AUTH="--config $CURL_CONFIG"

for db in "${DATABASES[@]}"; do
  echo "🗜️  Compacting $db..."
  curl -sf $AUTH -X POST "$BASE/$db/_compact" \
    -H "Content-Type: application/json" > /dev/null
  echo "   ✅ Done."
done

echo ""
echo "✅ All databases compacted."
