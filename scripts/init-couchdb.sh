#!/bin/bash
# =============================================================
# scripts/init-couchdb.sh
# Initializes CouchDB with the settings LiveSync requires.
# Run ONCE at install time, after the CouchDB container is up
# and running.
# =============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../config/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Error: $ENV_FILE not found."
  echo "   Copy config/.env.example to config/.env and fill in the values."
  exit 1
fi

# Load environment variables
source "$ENV_FILE"

COUCHDB_URL="http://localhost:5984"

echo "🔄 Waiting for CouchDB to start..."
until curl -sf "$COUCHDB_URL/_up" > /dev/null 2>&1; do
  sleep 2
done
echo "✅ CouchDB is up."

INIT_SCRIPT=$(mktemp /tmp/livesync-init-XXXXXX.sh)
echo "⬇️  Downloading the LiveSync init script to $INIT_SCRIPT ..."
curl -sf "https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/couchdb/couchdb-init.sh" \
  -o "$INIT_SCRIPT"

echo ""
echo "   Review it if you'd like before continuing:"
echo "   cat $INIT_SCRIPT"
echo ""
read -rp "   Run the script? [y/N] " REPLY
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
  echo "   Aborted. Review $INIT_SCRIPT and run it manually if you want to continue."
  exit 1
fi

echo "🔄 Running the LiveSync init script..."
# The LiveSync init script now requires Deno 2 (it runs a provision.ts-based
# setup internally). If Deno isn't available locally, run it in a temporary
# container on the couchdb-internal network instead.
if command -v deno > /dev/null 2>&1; then
  hostname="$COUCHDB_URL" \
    username="$COUCHDB_ADMIN_USER" \
    password="$COUCHDB_ADMIN_PASSWORD" \
    bash "$INIT_SCRIPT"
else
  echo "ℹ️  Deno not found locally — running the init script in a temporary container instead."
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
echo "✅ CouchDB initialized for LiveSync."
echo "   Now run: ./scripts/setup-users.sh"
