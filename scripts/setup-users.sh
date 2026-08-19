#!/bin/bash
# =============================================================
# scripts/setup-users.sh
# Skapar CouchDB-användare och databaser.
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

# =============================================================
# ANPASSA HÄR — ändra till dina egna användare och databaser.
# Lösenorden (USER1_PASSWORD, USER2_PASSWORD, SHARED_PASSWORD)
# definieras i config/.env.
# =============================================================
USER1_NAME="alice"
USER1_DB="vault-alice"

USER2_NAME="bob"
USER2_DB="vault-bob"

SHARED_NAME="shared-user"
SHARED_DB="vault-shared"
SHARED_MEMBERS=("$USER1_NAME" "$USER2_NAME" "$SHARED_NAME")
# =============================================================

BASE="http://localhost:5984"

# Credentials i en temporär fil — syns inte i process-listan (ps aux)
CURL_CONFIG=$(mktemp /tmp/curlrc-XXXXXX)
echo "user = \"${COUCHDB_ADMIN_USER}:${COUCHDB_ADMIN_PASSWORD}\"" > "$CURL_CONFIG"
chmod 600 "$CURL_CONFIG"
trap "rm -f $CURL_CONFIG" EXIT

AUTH="--config $CURL_CONFIG"

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
  shift
  local members=("$@")
  local json_members
  json_members=$(printf ',"%s"' "${members[@]}")
  json_members="[${json_members:1}]"
  echo "🔒 Sätter delad behörighet på '$dbname' → ${members[*]}"
  curl -sf $AUTH -X PUT "$BASE/$dbname/_security" \
    -H "Content-Type: application/json" \
    -d "{\"admins\":{\"names\":[],\"roles\":[]},\"members\":{\"names\":${json_members},\"roles\":[]}}" \
    > /dev/null && echo "   ✅ Behörighet satt." || echo "   ❌ Misslyckades."
}

echo ""
echo "=== Skapar användare ==="
create_user "$USER1_NAME" "$USER1_PASSWORD"
create_user "$USER2_NAME" "$USER2_PASSWORD"
create_user "$SHARED_NAME" "$SHARED_PASSWORD"

echo ""
echo "=== Skapar databaser ==="
create_database "$USER1_DB"
create_database "$USER2_DB"
create_database "$SHARED_DB"

echo ""
echo "=== Sätter behörigheter ==="
set_db_permissions "$USER1_DB" "$USER1_NAME"
set_db_permissions "$USER2_DB" "$USER2_NAME"
set_shared_db_permissions "$SHARED_DB" "${SHARED_MEMBERS[@]}"

echo ""
echo "✅ Klart! Sammanfattning:"
echo ""
echo "   Databas        Användare"
echo "   ----------     ---------"
echo "   $USER1_DB  →  $USER1_NAME (privat)"
echo "   $USER2_DB  →  $USER2_NAME (privat)"
echo "   $SHARED_DB  →  ${SHARED_MEMBERS[*]} (delad)"
echo ""
echo "   Nästa steg: Se docs/4-obsidian-plugin.md"
