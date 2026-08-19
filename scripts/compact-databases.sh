#!/bin/bash
# =============================================================
# scripts/compact-databases.sh
# Komprimerar CouchDB-databaser för att frigöra disk.
# CouchDB sparar alla revisioner — komprimering rensar gamla.
# Kör t.ex. månadsvis via cron.
# =============================================================

# =============================================================
# ANPASSA HÄR — lista alla dina CouchDB-databaser
# =============================================================
DATABASES=("vault-alice" "vault-bob" "vault-shared")
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../config/.env"

source "$ENV_FILE"

BASE="http://localhost:5984"

# Credentials i en temporär fil — syns inte i process-listan (ps aux)
CURL_CONFIG=$(mktemp /tmp/curlrc-XXXXXX)
echo "user = \"${COUCHDB_ADMIN_USER}:${COUCHDB_ADMIN_PASSWORD}\"" > "$CURL_CONFIG"
chmod 600 "$CURL_CONFIG"
trap "rm -f $CURL_CONFIG" EXIT

AUTH="--config $CURL_CONFIG"

for db in "${DATABASES[@]}"; do
  echo "🗜️  Komprimerar $db..."
  curl -sf $AUTH -X POST "$BASE/$db/_compact" \
    -H "Content-Type: application/json" > /dev/null
  echo "   ✅ Klar."
done

echo ""
echo "✅ Alla databaser komprimerade."
