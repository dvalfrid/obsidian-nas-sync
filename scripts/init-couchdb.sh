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

INIT_SCRIPT=$(mktemp /tmp/livesync-init-XXXXXX.sh)
echo "⬇️  Laddar ned LiveSync-init script till $INIT_SCRIPT ..."
curl -sf "https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/couchdb/couchdb-init.sh" \
  -o "$INIT_SCRIPT"

echo ""
echo "   Granska om du vill innan du fortsätter:"
echo "   cat $INIT_SCRIPT"
echo ""
read -rp "   Kör scriptet? [y/N] " REPLY
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
  echo "   Avbröts. Granska $INIT_SCRIPT och kör det manuellt om du vill fortsätta."
  exit 1
fi

echo "🔄 Kör LiveSync-init script..."
# LiveSync-init scriptet kräver numera Deno 2 (kör en provision.ts-baserad
# setup internt). Finns inte Deno lokalt körs scriptet istället i en
# tillfällig container på couchdb-internal-nätverket.
if command -v deno > /dev/null 2>&1; then
  hostname="$COUCHDB_URL" \
    username="$COUCHDB_ADMIN_USER" \
    password="$COUCHDB_ADMIN_PASSWORD" \
    bash "$INIT_SCRIPT"
else
  echo "ℹ️  Deno hittades inte lokalt — kör init-scriptet i en tillfällig container istället."
  docker run --rm \
    --network couchdb-internal \
    -e hostname="http://couchdb:5984" \
    -e username="$COUCHDB_ADMIN_USER" \
    -e password="$COUCHDB_ADMIN_PASSWORD" \
    -v "$INIT_SCRIPT:/tmp/init.sh:ro" \
    denoland/deno:bookworm \
    bash /tmp/init.sh
fi

rm -f "$INIT_SCRIPT"

echo ""
echo "✅ CouchDB initierad för LiveSync."
echo "   Kör nu: ./scripts/setup-users.sh"
