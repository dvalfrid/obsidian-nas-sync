# 1. NAS setup — CouchDB via Docker

## Prerequisites

- SSH enabled on your NAS (TOS → Control Panel → Terminal)
- Docker and Portainer enabled in TOS

---

## Step 1 — Clone the repo onto your NAS

SSH into your NAS and clone the repo:

```bash
ssh admin@<nas-ip>
cd /volume1
git clone https://github.com/dvalfrid/obsidian-nas-sync
cd obsidian-nas-sync
```

If git isn't installed:

```bash
# Install git via the TOS App Center, or run it via Docker directly in the next step
```

---

## Step 2 — Create a data folder

```bash
mkdir -p /volume1/docker/couchdb-obsidian/data
```

---

## Step 3 — Create the environment file

```bash
cp config/.env.example config/.env
nano config/.env
```

Fill in all the values — choose strong, unique passwords for every user. Consider using a password manager to generate them.

> **Note:** `.env` is never pushed to GitHub. Check that `.gitignore` contains `config/.env`.

---

## Step 4 — Start CouchDB

```bash
cd config
docker compose up -d
```

Verify the container is running:

```bash
docker ps | grep couchdb
```

Verify CouchDB responds:

```bash
curl http://localhost:5984/_up
# Expected response: {"status":"ok"}
```

---

## Step 5 — Initialize CouchDB for LiveSync

```bash
cd /volume1/obsidian-nas-sync
chmod +x scripts/*.sh
./scripts/init-couchdb.sh
```

You should see several `{"ok":true}` in the output.

> **Note:** the LiveSync project's init script requires **Deno 2** to run. If Deno isn't installed on your NAS, `init-couchdb.sh` automatically runs it in a temporary Docker container instead — no extra step needed, but this does require Docker to be able to pull the `denoland/deno:bookworm` image (i.e. internet access from the NAS).

---

## Step 6 — Create users and databases

First, edit the "CUSTOMIZE HERE" block at the top of `scripts/setup-users.sh` to use your own usernames and database names instead of the `alice`/`bob`/`shared-user` example (and add matching passwords to `config/.env` — see [docs/3-couchdb-users.md](docs/3-couchdb-users.md)).

```bash
./scripts/setup-users.sh
```

Check the result in the CouchDB admin UI (Fauxton):

```
http://localhost:5984/_utils/
```

Log in with your admin credentials and verify that your databases exist.

---

## Verify the security configuration

CouchDB should only listen on localhost — test that it is NOT reachable from outside:

```bash
# Run from another machine on the network — should FAIL
curl http://<nas-ip>:5984/_up
# Expected: connection refused or timeout
```

All external access happens via the Cloudflare Tunnel (see the next step).

---

## Next step

→ [2-cloudflare-tunnel.md](2-cloudflare-tunnel.md)
