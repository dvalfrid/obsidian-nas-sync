#!/bin/bash
# =============================================================
# scripts/compact-databases.sh
# Komprimerar CouchDB-databaser för att frigöra disk.
# CouchDB sparar alla revisioner — komprimering rensar gamla.
# Kör t.ex. månadsvis via cron.
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../config/.env"

source "$ENV_FILE"

BASE="http://$COUCHDB_ADMIN_USER:$COUCHDB_ADMIN_PASSWORD@localhost:5984"

for db in vault-daniel vault-linda vault-shared; do
  echo "🗜️  Komprimerar $db..."
  curl -sf -X POST "$BASE/$db/_compact" \
    -H "Content-Type: application/json" > /dev/null
  echo "   ✅ Klar."
done

echo ""
echo "✅ Alla databaser komprimerade."
