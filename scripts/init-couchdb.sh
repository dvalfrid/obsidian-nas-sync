#!/bin/bash
# =============================================================
# scripts/init-couchdb.sh
# Initierar CouchDB med nödvändiga inställningar för LiveSync.
# Körs EN GÅNG vid installation, efter att CouchDB-containern
# är uppe och kör.
# =============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../config/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Fel: $ENV_FILE hittades inte."
  echo "   Kopiera config/.env.example till config/.env och fyll i värdena."
  exit 1
fi

# Ladda miljövariabler
source "$ENV_FILE"

COUCHDB_URL="http://localhost:5984"

echo "🔄 Väntar på att CouchDB ska starta..."
until curl -sf "$COUCHDB_URL/_up" > /dev/null 2>&1; do
  sleep 2
done
echo "✅ CouchDB är uppe."

echo "🔄 Kör LiveSync-init script..."
curl -s https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/couchdb/couchdb-init.sh | \
  hostname="$COUCHDB_URL" \
  username="$COUCHDB_ADMIN_USER" \
  password="$COUCHDB_ADMIN_PASSWORD" \
  bash

echo ""
echo "✅ CouchDB initierad för LiveSync."
echo "   Kör nu: ./scripts/setup-users.sh"
