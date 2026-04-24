# 1. NAS-setup — CouchDB via Docker

## Förkrav

- SSH aktiverat på NAS:en (TOS → Kontrollpanel → Terminal)
- Docker och Portainer aktiverade i TOS

---

## Steg 1 — Klona repot till NAS:en

SSH in på NAS:en och klona repot:

```bash
ssh admin@<nas-ip>
cd /volume1
git clone https://github.com/DITT_REPO/obsidian-nas-sync
cd obsidian-nas-sync
```

Om git inte finns installerat:

```bash
# Installera git via TOS App Center, eller kör direkt via Docker i nästa steg
```

---

## Steg 2 — Skapa datamapp

```bash
mkdir -p /volume1/docker/couchdb-obsidian/data
```

---

## Steg 3 — Skapa miljöfil

```bash
cp config/.env.example config/.env
nano config/.env
```

Fyll i alla värden — välj starka, unika lösenord för varje användare. Använd t.ex. en lösenordshanterare för att generera dem.

> **OBS:** `.env` pushas aldrig till GitHub. Kontrollera att `.gitignore` innehåller `config/.env`.

---

## Steg 4 — Starta CouchDB

```bash
cd config
docker compose up -d
```

Verifiera att containern kör:

```bash
docker ps | grep couchdb
```

Verifiera att CouchDB svarar:

```bash
curl http://localhost:5984/_up
# Förväntat svar: {"status":"ok"}
```

---

## Steg 5 — Initiera CouchDB för LiveSync

```bash
cd /volume1/obsidian-nas-sync
chmod +x scripts/*.sh
./scripts/init-couchdb.sh
```

Du ska se flera `{"ok":true}` i utdata.

---

## Steg 6 — Skapa användare och databaser

```bash
./scripts/setup-users.sh
```

Kontrollera resultatet i CouchDB-admin (Fauxton):

```
http://localhost:5984/_utils/
```

Logga in med admin-credentials och verifiera att tre databaser finns:
- `vault-daniel`
- `vault-linda`
- `vault-shared`

---

## Verifiera säkerhetskonfiguration

CouchDB ska bara lyssna på localhost — testa att den INTE är åtkomlig utifrån:

```bash
# Kör från en annan maskin i nätverket — ska MISSLYCKAS
curl http://<nas-ip>:5984/_up
# Förväntat: connection refused eller timeout
```

All extern åtkomst sker via Cloudflare Tunnel (se nästa steg).

---

## Nästa steg

→ [2-cloudflare-tunnel.md](2-cloudflare-tunnel.md)
