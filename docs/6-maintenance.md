# 6. Maintenance, backup, and troubleshooting

---

## Regular maintenance

### Compact databases (monthly)

CouchDB keeps every revision of your notes. Without compaction, the database file grows unnecessarily.

```bash
cd /volume1/obsidian-nas-sync
./scripts/compact-databases.sh
```

Or set up an automatic cron job via TOS (Control Panel → Scheduled Tasks):

```
0 3 1 * * /volume1/obsidian-nas-sync/scripts/compact-databases.sh
```

(Runs at 3:00 AM on the 1st of every month)

### Update Docker images

```bash
cd /volume1/obsidian-nas-sync/config
docker compose pull
docker compose down
docker compose up -d
```

> **Tip:** `cloudflare/cloudflared` is pinned to a specific version in `docker-compose.yml` (currently `2026.8.2`) so upgrades happen deliberately — not automatically on the next `docker compose pull`. Bump the version number manually when you want to upgrade. Find the latest version at [github.com/cloudflare/cloudflared/releases](https://github.com/cloudflare/cloudflared/releases).

---

## Backup

### What needs backing up

| What | Where | Why |
|---|---|---|
| CouchDB data | `/volume1/docker/couchdb-obsidian/data/` | All your notes |
| Configuration | `/volume1/obsidian-nas-sync/config/.env` | Passwords and token |
| Repo | GitHub | Everything else |

### Backup with TerraMaster Duple Backup

TOS has a built-in Duple Backup tool — configure it to back up `/volume1/docker/couchdb-obsidian/data/` to another disk or an external destination.

### Manual backup

```bash
# Create a compressed backup of the CouchDB data
tar -czf ~/couchdb-backup-$(date +%Y%m%d).tar.gz \
  /volume1/docker/couchdb-obsidian/data/
```

> **Note:** LiveSync automatically keeps a full local copy of the vault on every device. If your NAS crashes, you still have all your notes locally on your computer/phone.

---

## Troubleshooting

### CouchDB isn't responding

```bash
# Check that the container is running
docker ps | grep couchdb

# View logs
docker logs couchdb-obsidian --tail 50

# Restart it
docker restart couchdb-obsidian
```

### The Cloudflare Tunnel is down

```bash
# Check that the container is running
docker ps | grep cloudflared

# View logs
docker logs cloudflared-nas --tail 50

# Restart it
docker restart cloudflared-nas
```

Also check in [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) → Networks → Tunnels that the status is Healthy.

### LiveSync isn't syncing

1. Check that `https://<your-subdomain>/_up` responds
2. In Obsidian → LiveSync settings → **Test** (Connection test)
3. Open Obsidian Developer Tools (Ctrl+Shift+I) → Console for error messages
4. Check that the correct database and credentials are being used

### "Unauthorized" despite the correct password

CouchDB sessions expire. Try:
- Closing and reopening Obsidian
- Or: LiveSync → Disconnect → Reconnect

### Database is full / performance is poor

Run `compact-databases.sh` (see above).

---

## Recovering after a NAS failure

1. Install Docker and clone the repo on the new/restored NAS
2. Copy the CouchDB backup to `/volume1/docker/couchdb-obsidian/data/`
3. Recreate `config/.env` with your saved credentials
4. Run `docker compose up -d`
5. Verify with `curl https://<your-subdomain>/_up`

No changes are needed in Obsidian on client devices — they reconnect automatically once the server is back.

---

## Security check (run occasionally)

```bash
# Verify CouchDB is NOT directly reachable (should fail)
curl http://<nas-ip>:5984/_up

# Verify anonymous access is blocked
curl https://<your-subdomain>/_all_dbs
# Expected: {"error":"unauthorized",...}

# Verify cross-user isolation works
curl -u alice:ALICE_PASS https://<your-subdomain>/vault-bob
# Expected: {"error":"unauthorized",...}

# Verify the Fauxton admin panel is blocked externally (WAF rule)
curl -i https://<your-subdomain>/_utils/
# Expected: HTTP 403 (Cloudflare blocking it — see docs/2-cloudflare-tunnel.md)

# Verify cloudflared is running without host networking
docker inspect cloudflared-nas | grep -A5 NetworkMode
# Expected: "NetworkMode": "couchdb-internal" (NOT "host")
```
