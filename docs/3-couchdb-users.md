# 3. CouchDB — users and databases

`setup-users.sh` handles most of this automatically. This document explains what gets created and how to verify it.

---

## What gets created

### Users

| User | Vault | Password (source) |
| --- | --- | --- |
| `admin` | Administration | `COUCHDB_ADMIN_PASSWORD` in `.env` |
| `alice` (USER1_NAME) | vault-alice (private) | `USER1_PASSWORD` in `.env` |
| `bob` (USER2_NAME) | vault-bob (private) | `USER2_PASSWORD` in `.env` |
| `shared-user` | vault-shared (shared) | `SHARED_PASSWORD` in `.env` |

> The example names above (`alice`, `bob`) are placeholders. The actual names are defined in the "CUSTOMIZE HERE" block in `scripts/setup-users.sh`.

### Databases and permissions

| Database | Read/write | Admin |
| --- | --- | --- |
| `vault-alice` | alice | (none, only the CouchDB admin) |
| `vault-bob` | bob | (none, only the CouchDB admin) |
| `vault-shared` | alice, bob, shared-user | (none, only the CouchDB admin) |

Private vaults are isolated — users cannot access each other's vaults.

---

## What you need to customize

Before running `setup-users.sh` — edit the "CUSTOMIZE HERE" block near the top of the script:

```bash
USER1_NAME="alice"       # change to your actual username
USER1_DB="vault-alice"   # change to your actual database name

USER2_NAME="bob"
USER2_DB="vault-bob"

SHARED_NAME="shared-user"
SHARED_DB="vault-shared"
SHARED_MEMBERS=("$USER1_NAME" "$USER2_NAME" "$SHARED_NAME")
```

And add matching passwords to `config/.env`:

```env
USER1_PASSWORD=your-strong-password-here
USER2_PASSWORD=your-strong-password-here
SHARED_PASSWORD=your-strong-password-here
```

Same for `scripts/compact-databases.sh` — update the `DATABASES` list there with your actual database names.

---

## Verify via Fauxton (web UI)

Open the CouchDB admin UI locally on your NAS:

```
http://localhost:5984/_utils/
```

Log in with your admin credentials and check:

- **Databases**: should show your vaults
- **_users**: should show all vault users

> `/_utils` is blocked externally via the Cloudflare WAF (see `docs/2-cloudflare-tunnel.md`).

---

## Verify via curl

```bash
# List databases (as admin)
curl -u admin:ADMIN_PASSWORD https://<your-subdomain>/_all_dbs

# Test that user1 can reach their vault
curl -u alice:USER1_PASSWORD https://<your-subdomain>/vault-alice

# Test that user1 CANNOT reach user2's vault
curl -u alice:USER1_PASSWORD https://<your-subdomain>/vault-bob
# Expected: {"error":"unauthorized",...}

# Test that user2 can reach the shared vault
curl -u bob:USER2_PASSWORD https://<your-subdomain>/vault-shared
# Expected: {"db_name":"vault-shared",...}
```

---

## Adding more vaults later

Add to the "CUSTOMIZE HERE" block in `setup-users.sh` and run the script again:

```bash
# In config/.env
USER3_PASSWORD=your-strong-password-here

# In scripts/setup-users.sh (the CUSTOMIZE HERE block)
USER3_NAME="carol"
USER3_DB="vault-carol"
```

Then add matching `create_user`, `create_database`, and `set_db_permissions` calls in the script, and update the `DATABASES` list in `compact-databases.sh`.

---

## Next step

→ [4-obsidian-plugin.md](4-obsidian-plugin.md)
