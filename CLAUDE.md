# CLAUDE.md — Context for the AI assistant

This document describes the project's architecture, design decisions, and conventions so an AI assistant can help with changes without needing to ask basic questions.

Instance-specific information (domain, names, hardware) lives in `CLAUDE.local.md` (gitignored).

---

## What this project does

Self-hosted Obsidian sync solution for a household, running on a NAS.

- Sync engine: **CouchDB** (via Docker) + **Self-hosted LiveSync** (Obsidian plugin)
- Exposure: **Cloudflare Tunnel** → your own subdomain (no open port on the router)
- Separate CouchDB databases, one per vault

---

## Architecture

```text
Obsidian client
  │ HTTPS
  ▼
Cloudflare (terminates TLS)
  │ via Cloudflare Tunnel
  ▼
cloudflared container  (Docker network: couchdb-internal)
  │ HTTP, internal
  ▼
CouchDB container  (port 5984, localhost only on the host)
  │
  ▼
/Volume.../docker/couchdb-.../data  (NAS volume)
```

---

## Docker Compose files

`config/docker-compose.yml` starts two containers:

1. `couchdb` — the database, port mapped to `127.0.0.1:5984` on the host (not directly reachable from outside)
2. `cloudflared` — the Cloudflare Tunnel client, reaches CouchDB via the Docker network (`http://couchdb:5984`)

Both containers run in a dedicated Docker bridge network (`couchdb-internal`). cloudflared does **not** use `network_mode: host` — that limits its reach to just the CouchDB container.

The `127.0.0.1:5984:5984` port mapping is kept so admin scripts can be run from the host.

---

## CouchDB configuration

`config/couchdb/local.ini` contains:

- CORS settings for the Obsidian app (`app://obsidian.md`, `capacitor://localhost`)
- `require_valid_user = true` — no anonymous access

CouchDB's binding to `127.0.0.1` is handled by the Docker port mapping (`127.0.0.1:5984:5984`), not by `bind_address` in local.ini.

The file is mounted read-only into the container.

---

## Vault structure

Each household member has a private vault. There's also a shared vault. See `CLAUDE.local.md` for the actual vault names, database names, and usernames.

The principle:

- Private vaults: only that individual user has access
- Shared vault: every relevant user has access

Permissions are set via CouchDB's `_security` document per database.

---

## Scripts

| Script | Purpose | Run |
| --- | --- | --- |
| `scripts/init-couchdb.sh` | Downloads and runs CouchDB init from the LiveSync project | Once, at install time |
| `scripts/setup-users.sh` | Creates CouchDB users and databases | Once, at install time |
| `scripts/compact-databases.sh` | Compacts CouchDB databases | Periodically (cron) |

All scripts read credentials from `config/.env`. Credentials are passed to curl via a temporary config file (not visible in the process list).

`init-couchdb.sh` downloads an external script and asks for confirmation before running it — review it before answering yes.

---

## Environment variables (config/.env)

```
COUCHDB_ADMIN_USER=...
COUCHDB_ADMIN_PASSWORD=...
# One line per vault user, e.g.:
# USER1_PASSWORD=...
# USER2_PASSWORD=...
CLOUDFLARE_TUNNEL_TOKEN=...
```

`.env` is in `.gitignore` — never pushed to GitHub. Copy `config/.env.example` and fill it in.

---

## Common changes

**Adding a new vault:**

1. Add the user and database to `scripts/setup-users.sh`
2. Run `setup-users.sh` again
3. Generate a new Setup URI and share it with the user (see `docs/5-sharing.md`)

**Changing a password:**

1. Update `config/.env`
2. Run `docker compose down && docker compose up -d`
3. Update the Setup URI in Obsidian on all affected devices

**Moving to a new NAS:**

1. Copy the CouchDB data volume
2. Copy the `config/` folder (including `.env`)
3. Run `docker compose up -d` on the new NAS
4. Update the Cloudflare Tunnel with the new `cloudflared` container

---

## What NOT to change without careful thought

- The `127.0.0.1:5984:5984` port mapping (security-critical — keeps CouchDB off the host's external interfaces)
- `network_mode: host` must **not** be reintroduced for cloudflared
- `require_valid_user` in `local.ini` (security-critical)
- The Cloudflare Tunnel token (regenerate in the Zero Trust dashboard if needed)
- Database names (LiveSync's configuration on every device must be updated if these change)
