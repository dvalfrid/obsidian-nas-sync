# 2. Cloudflare Tunnel — your domain → your NAS

---

## Architecture

```text
Internet
  │
  ▼
<your-subdomain>  (Cloudflare → CNAME → tunnel-id.cfargotunnel.com)
  │
  ▼ HTTPS (Cloudflare terminates TLS)
Cloudflare Tunnel (cloudflared container on your NAS)
  │
  ▼ HTTP (internal, Docker network)
CouchDB on port 5984
```

---

## Step 1 — Create a new tunnel in Cloudflare

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. **Networks → Tunnels → Create a tunnel**
3. Choose **Cloudflared** as the connector type
4. Name the tunnel `nas-obsidian`
5. Choose **Docker** as the installation method
6. Copy the **token** shown (starts with `eyJ...`)

---

## Step 2 — Add the token to .env

Open `config/.env` on your NAS and add the token:

```bash
nano /volume1/obsidian-nas-sync/config/.env
```

```env
CLOUDFLARE_TUNNEL_TOKEN=eyJ...YOUR_TOKEN_HERE...
```

---

## Step 3 — Restart Docker Compose

The `cloudflared` container is already defined in `config/docker-compose.yml`. Restart it to pick up the token:

```bash
cd /volume1/obsidian-nas-sync/config
docker compose down
docker compose up -d
```

---

## Step 4 — Verify the tunnel is connected

Back in the Cloudflare Zero Trust dashboard:

- **Networks → Tunnels**
- The `nas-obsidian` tunnel should now show status **"Healthy"** (green)

---

## Step 5 — Add a Public Hostname

In the Zero Trust dashboard, click `nas-obsidian` → **Configure → Public Hostnames → Add a public hostname** and fill in:

| Field | Value |
| --- | --- |
| Subdomain | `obsidian` (or your own choice) |
| Domain | `<your-domain>` |
| Type | `HTTP` |
| URL | `couchdb:5984` |

Click **Save hostname**. Cloudflare creates the DNS record (CNAME) automatically.

> **Why `couchdb:5984` and not `localhost:5984`?**
> cloudflared runs in its own Docker network (not host networking). `localhost` inside the container points at the container itself, not the host. Docker resolves `couchdb` to the right container via its internal DNS.

---

## Step 6 — Test HTTPS access

From any device (not the NAS itself):

```bash
curl https://<your-subdomain>/_up
# Expected response: {"status":"ok"}
```

Test that authentication is required:

```bash
curl https://<your-subdomain>/_all_dbs
# Expected: {"error":"unauthorized","reason":"You are not a server admin."}
```

---

## Hardening in the Cloudflare dashboard

These steps are done once in the [Cloudflare dashboard](https://dash.cloudflare.com/) (not Zero Trust) under **Websites → \<your-domain\>**.

### Block the Fauxton admin panel (`/_utils`)

CouchDB's built-in web UI shouldn't be reachable from outside.

1. Go to **Security → WAF → Custom rules → Create rule**
2. Fill in:
   - **Rule name:** Block CouchDB admin panel
   - **Field:** URI Path — **operator:** starts with — **value:** `/_utils`
   - **Action:** Block
3. Click **Deploy**

### Rate-limit login attempts

Protects against brute-force attacks on CouchDB passwords.

1. Go to **Security → WAF → Rate limiting rules → Create rule**
2. Fill in:
   - **Rule name:** Limit CouchDB auth attempts
   - **Field:** URI Path — **operator:** equals — **value:** `/_session`
   - **Threshold:** 15 requests per 10 seconds per IP
   - **Action:** Block — Duration: 10 seconds
3. Click **Deploy**

> `/_session` is CouchDB's authentication endpoint — every LiveSync login attempt goes there. Rate limiting rules can't filter by subdomain directly, but if you host other unrelated services on the same domain, check that they don't also use a `/_session` path before relying on this rule.
>
> **Free-plan limitation:** Cloudflare Free only allows a 10-second block, meaning a persistent attacker could try ~90 passwords per minute. The primary protection is therefore strong, unique passwords — not rate limiting.

---

## Next step

→ [3-couchdb-users.md](3-couchdb-users.md)
