#!/bin/bash
# =============================================================
# scripts/setup-users.sh
# Creates CouchDB users and databases.
# Run ONCE at install time (or whenever a vault is added).
# =============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../config/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Error: $ENV_FILE not found."
  exit 1
fi

source "$ENV_FILE"

# =============================================================
# CUSTOMIZE HERE — change to your own users and databases.
# The passwords (USER1_PASSWORD, USER2_PASSWORD, SHARED_PASSWORD)
# are defined in config/.env.
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

# Credentials in a temp file — not visible in the process list (ps aux)
CURL_CONFIG=$(mktemp /tmp/curlrc-XXXXXX)
echo "user = \"${COUCHDB_ADMIN_USER}:${COUCHDB_ADMIN_PASSWORD}\"" > "$CURL_CONFIG"
chmod 600 "$CURL_CONFIG"
trap "rm -f $CURL_CONFIG" EXIT

AUTH="--config $CURL_CONFIG"

create_user() {
  local username=$1
  local password=$2
  echo "👤 Creating user: $username"
  curl -sf $AUTH -X PUT "$BASE/_users/org.couchdb.user:$username" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$username\",\"password\":\"$password\",\"roles\":[],\"type\":\"user\"}" \
    > /dev/null && echo "   ✅ User '$username' created." || echo "   ⚠️  User '$username' already exists (ok)."
}

create_database() {
  local dbname=$1
  echo "🗄️  Creating database: $dbname"
  curl -sf $AUTH -X PUT "$BASE/$dbname" > /dev/null && \
    echo "   ✅ Database '$dbname' created." || \
    echo "   ⚠️  Database '$dbname' already exists (ok)."
}

set_db_permissions() {
  local dbname=$1
  local member=$2
  echo "🔒 Setting permissions on '$dbname' → '$member'"
  curl -sf $AUTH -X PUT "$BASE/$dbname/_security" \
    -H "Content-Type: application/json" \
    -d "{\"admins\":{\"names\":[],\"roles\":[]},\"members\":{\"names\":[\"$member\"],\"roles\":[]}}" \
    > /dev/null && echo "   ✅ Permissions set." || echo "   ❌ Failed."
}

set_shared_db_permissions() {
  local dbname=$1
  shift
  local members=("$@")
  local json_members
  json_members=$(printf ',"%s"' "${members[@]}")
  json_members="[${json_members:1}]"
  echo "🔒 Setting shared permissions on '$dbname' → ${members[*]}"
  curl -sf $AUTH -X PUT "$BASE/$dbname/_security" \
    -H "Content-Type: application/json" \
    -d "{\"admins\":{\"names\":[],\"roles\":[]},\"members\":{\"names\":${json_members},\"roles\":[]}}" \
    > /dev/null && echo "   ✅ Permissions set." || echo "   ❌ Failed."
}

echo ""
echo "=== Creating users ==="
create_user "$USER1_NAME" "$USER1_PASSWORD"
create_user "$USER2_NAME" "$USER2_PASSWORD"
create_user "$SHARED_NAME" "$SHARED_PASSWORD"

echo ""
echo "=== Creating databases ==="
create_database "$USER1_DB"
create_database "$USER2_DB"
create_database "$SHARED_DB"

echo ""
echo "=== Setting permissions ==="
set_db_permissions "$USER1_DB" "$USER1_NAME"
set_db_permissions "$USER2_DB" "$USER2_NAME"
set_shared_db_permissions "$SHARED_DB" "${SHARED_MEMBERS[@]}"

echo ""
echo "✅ Done! Summary:"
echo ""
echo "   Database       Users"
echo "   ----------     ---------"
echo "   $USER1_DB  →  $USER1_NAME (private)"
echo "   $USER2_DB  →  $USER2_NAME (private)"
echo "   $SHARED_DB  →  ${SHARED_MEMBERS[*]} (shared)"
echo ""
echo "   Next step: see docs/4-obsidian-plugin.md"
