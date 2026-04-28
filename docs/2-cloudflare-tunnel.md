# 2. Cloudflare Tunnel — obsidian.valfridsson.se → NAS

Du har redan tunnlar mot Mac Pro:n (calendar, bluebubble). Det här är ett **separat, nytt tunnel** som pekar direkt mot NAS:en — Mac Pro:n påverkas inte.

---

## Arkitektur

```text
Internet
  │
  ▼
obsidian.valfridsson.se  (Cloudflare → CNAME → tunnel-id.cfargotunnel.com)
  │
  ▼ HTTPS (Cloudflare terminerar TLS)
Cloudflare Tunnel (cloudflared-container på NAS)
  │
  ▼ HTTP (intern, Docker-nätverk)
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

I Zero Trust-dashboarden, klicka på `nas-obsidian` → **Configure → Public Hostnames → Add a public hostname** och fyll i:

| Fält | Värde |
| --- | --- |
| Subdomain | `obsidian` |
| Domain | `valfridsson.se` |
| Type | `HTTP` |
| URL | `couchdb:5984` |

Klicka **Save hostname**. Cloudflare skapar DNS-posten (CNAME) automatiskt.

> **Varför `couchdb:5984` och inte `localhost:5984`?**
> cloudflared kör i ett eget Docker-nätverk (ej host-networking). `localhost` inom containern pekar på containern själv, inte hosten. Docker löser upp `couchdb` till rätt container via sitt interna DNS.

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

## Säkerhetshärdning i Cloudflare-dashboarden

Dessa steg görs en gång i [Cloudflare-dashboarden](https://dash.cloudflare.com/) (inte Zero Trust) under **Websites → valfridsson.se**.

### Blockera Fauxton-adminpanelen (`/_utils`)

CouchDB:s inbyggda webbgränssnitt ska inte vara åtkomligt utifrån.

1. Gå till **Security → WAF → Custom rules → Create rule**
2. Fyll i:
   - **Rule name:** Block CouchDB admin panel
   - **Field:** URI Path — **operator:** starts with — **value:** `/_utils`
   - **Action:** Block
3. Klicka **Deploy**

### Begränsa inloggningsförsök (Rate Limiting)

Skyddar mot brute-force-attacker mot CouchDB-lösenord.

1. Gå till **Security → WAF → Rate limiting rules → Create rule**
2. Fyll i:
   - **Rule name:** Limit CouchDB auth attempts
   - **Field:** URI Path — **operator:** equals — **value:** `/_session`
   - **Threshold:** 15 requests per 10 seconds per IP
   - **Action:** Block — Duration: 10 seconds
3. Klicka **Deploy**

> `/_session` är CouchDB:s autentiseringsendpoint — dit går varje inloggningsförsök från LiveSync. Rate Limiting-regler kan inte filtrera på subdomän direkt, men `/_session` förekommer inte på dina Mac Pro-subdomäner så det är tillräckligt specifikt.
>
> **Free-plan-begränsning:** Cloudflare Free tillåter bara 10 sekunders blockering, vilket innebär att en angripare kan försöka ~90 lösenord per minut om de är ihärdiga. Det primära skyddet är därför starka, unika lösenord — inte rate limiting.

---

## Skillnad mot Mac Pro-tunneln

| | Mac Pro-tunnel | NAS-tunnel |
| --- | --- | --- |
| Tunnel-namn | (ditt befintliga) | `nas-obsidian` |
| Subdomäner | calendar, bluebubble | obsidian |
| Kör på | Mac Pro | TerraMaster NAS |
| Oberoende? | Ja | Ja |

De två tunnlarna är helt oberoende av varandra. Om Mac Pro:n stängs av fortsätter NAS-tunneln fungera och vice versa.

---

## Nästa steg

→ [3-couchdb-users.md](3-couchdb-users.md)
