#!/bin/bash
# =============================================================
# scripts/setup-users.sh
# Skapar CouchDB-användare och databaser för alla tre vaults.
# Körs EN GÅNG vid installation (eller vid tillägg av vault).
# =============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../config/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Fel: $ENV_FILE hittades inte."
  exit 1
fi

source "$ENV_FILE"

BASE="http://localhost:5984"
AUTH="-u $COUCHDB_ADMIN_USER:$COUCHDB_ADMIN_PASSWORD"

create_user() {
  local username=$1
  local password=$2
  echo "👤 Skapar användare: $username"
  curl -sf $AUTH -X PUT "$BASE/_users/org.couchdb.user:$username" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$username\",\"password\":\"$password\",\"roles\":[],\"type\":\"user\"}" \
    > /dev/null && echo "   ✅ Användare '$username' skapad." || echo "   ⚠️  Användare '$username' finns redan (ok)."
}

create_database() {
  local dbname=$1
  echo "🗄️  Skapar databas: $dbname"
  curl -sf $AUTH -X PUT "$BASE/$dbname" > /dev/null && \
    echo "   ✅ Databas '$dbname' skapad." || \
    echo "   ⚠️  Databas '$dbname' finns redan (ok)."
}

set_db_permissions() {
  local dbname=$1
  local member=$2
  echo "🔒 Sätter behörighet på '$dbname' → '$member'"
  curl -sf $AUTH -X PUT "$BASE/$dbname/_security" \
    -H "Content-Type: application/json" \
    -d "{\"admins\":{\"names\":[],\"roles\":[]},\"members\":{\"names\":[\"$member\"],\"roles\":[]}}" \
    > /dev/null && echo "   ✅ Behörighet satt." || echo "   ❌ Misslyckades."
}

set_shared_db_permissions() {
  local dbname=$1
  echo "🔒 Sätter delad behörighet på '$dbname' → daniel, linda, shared-user"
  curl -sf $AUTH -X PUT "$BASE/$dbname/_security" \
    -H "Content-Type: application/json" \
    -d "{\"admins\":{\"names\":[],\"roles\":[]},\"members\":{\"names\":[\"daniel\",\"linda\",\"shared-user\"],\"roles\":[]}}" \
    > /dev/null && echo "   ✅ Behörighet satt." || echo "   ❌ Misslyckades."
}

echo ""
echo "=== Skapar användare ==="
create_user "daniel" "$DANIEL_PASSWORD"
create_user "linda" "$LINDA_PASSWORD"
create_user "shared-user" "$SHARED_PASSWORD"

echo ""
echo "=== Skapar databaser ==="
create_database "vault-daniel"
create_database "vault-linda"
create_database "vault-shared"

echo ""
echo "=== Sätter behörigheter ==="
set_db_permissions "vault-daniel" "daniel"
set_db_permissions "vault-linda" "linda"
set_shared_db_permissions "vault-shared"

echo ""
echo "✅ Klart! Sammanfattning:"
echo ""
echo "   Databas          Användare"
echo "   -----------      ---------"
echo "   vault-daniel  →  daniel (privat)"
echo "   vault-linda   →  linda (privat)"
echo "   vault-shared  →  daniel, linda, shared-user (delad)"
echo ""
echo "   Nästa steg: Se docs/4-obsidian-plugin.md"
