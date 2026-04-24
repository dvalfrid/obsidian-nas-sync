# 2. Cloudflare Tunnel — obsidian.valfridsson.se → NAS

Du har redan tunnlar mot Mac Pro:n (calendar, bluebubble). Det här är ett **separat, nytt tunnel** som pekar direkt mot NAS:en — Mac Pro:n påverkas inte.

---

## Arkitektur

```
Internet
  │
  ▼
obsidian.valfridsson.se  (Cloudflare → CNAME → tunnel-id.cfargotunnel.com)
  │
  ▼ HTTPS (Cloudflare terminerar TLS)
Cloudflare Tunnel (cloudflared-container på NAS)
  │
  ▼ HTTP (intern, localhost)
CouchDB på port 5984
```

---

## Steg 1 — Skapa nytt tunnel i Cloudflare

1. Gå till [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. **Networks → Tunnels → Create a tunnel**
3. Välj **Cloudflared** som connector-typ
4. Döp tunneln till `nas-obsidian`
5. Välj **Docker** som installation
6. Kopiera **token** som visas (börjar med `eyJ...`)

---

## Steg 2 — Lägg till token i .env

Öppna `config/.env` på NAS:en och lägg in token:

```bash
nano /volume1/obsidian-nas-sync/config/.env
```

```env
CLOUDFLARE_TUNNEL_TOKEN=eyJ...TOKEN_HÄR...
```

---

## Steg 3 — Starta om Docker Compose

`cloudflared`-containern är redan definierad i `config/docker-compose.yml`. Starta om för att aktivera den med rätt token:

```bash
cd /volume1/obsidian-nas-sync/config
docker compose down
docker compose up -d
```

---

## Steg 4 — Verifiera att tunneln är ansluten

Tillbaka i Cloudflare Zero Trust-dashboarden:
- **Networks → Tunnels**
- Tunneln `nas-obsidian` ska nu visa status **"Healthy"** (grönt)

---

## Steg 5 — Lägg till Public Hostname

I Zero Trust-dashboarden:

1. Klicka på `nas-obsidian` → **Configure → Public Hostnames → Add a public hostname**
2. Fyll i:

| Fält | Värde |
|---|---|
| Subdomain | `obsidian` |
| Domain | `valfridsson.se` |
| Type | `HTTP` |
| URL | `localhost:5984` |

3. Klicka **Save hostname**

Cloudflare skapar DNS-posten (CNAME) automatiskt.

---

## Steg 6 — Testa HTTPS-åtkomst

Från vilken enhet som helst (inte NAS:en):

```bash
curl https://obsidian.valfridsson.se/_up
# Förväntat svar: {"status":"ok"}
```

Testa att autentisering krävs:

```bash
curl https://obsidian.valfridsson.se/_all_dbs
# Förväntat: {"error":"unauthorized","reason":"You are not a server admin."}
```

---

## Skillnad mot Mac Pro-tunneln

| | Mac Pro-tunnel | NAS-tunnel |
|---|---|---|
| Tunnel-namn | (ditt befintliga) | `nas-obsidian` |
| Subdomäner | calendar, bluebubble | obsidian |
| Kör på | Mac Pro | TerraMaster NAS |
| Oberoende? | Ja | Ja |

De två tunnlarna är helt oberoende av varandra. Om Mac Pro:n stängs av fortsätter NAS-tunneln fungera och vice versa.

---

## Nästa steg

→ [3-couchdb-users.md](3-couchdb-users.md)
