# CLAUDE.md — Kontext för AI-assistenten

Det här dokumentet beskriver projektets arkitektur, designbeslut och konventioner så att en AI-assistent kan hjälpa till med ändringar utan att behöva ställa grundläggande frågor.

Instansspecifik information (domän, namn, hårdvara) finns i `CLAUDE.local.md` (gitignorerad).

---

## Vad projektet gör

Self-hosted Obsidian-synklösning för ett hushåll på en NAS.

- Synkmotor: **CouchDB** (via Docker) + **Self-hosted LiveSync** (Obsidian-plugin)
- Exponering: **Cloudflare Tunnel** → egen subdomän (ingen öppen port i router)
- Separata CouchDB-databaser, en per vault

---

## Arkitektur

```text
Obsidian-klient
  │ HTTPS
  ▼
Cloudflare (terminerar TLS)
  │ via Cloudflare Tunnel
  ▼
cloudflared-container  (Docker-nätverk: couchdb-internal)
  │ HTTP, intern
  ▼
CouchDB-container  (port 5984, endast localhost på hosten)
  │
  ▼
/Volume.../docker/couchdb-.../data  (NAS-volym)
```

---

## Docker Compose-filer

`config/docker-compose.yml` startar två containers:

1. `couchdb` — databasen, port mappas till `127.0.0.1:5984` på hosten (ej åtkomlig utifrån direkt)
2. `cloudflared` — Cloudflare Tunnel-klienten, når CouchDB via Docker-nätverket (`http://couchdb:5984`)

Båda containers kör i ett dedikerat Docker bridge-nätverk (`couchdb-internal`). cloudflared använder **inte** `network_mode: host` — det begränsar dess åtkomst till enbart CouchDB-containern.

Port-mappningen `127.0.0.1:5984:5984` behålls för att admin-scripts ska kunna köras från hosten.

---

## CouchDB-konfiguration

`config/couchdb/local.ini` innehåller:

- CORS-inställningar för Obsidian-appen (`app://obsidian.md`, `capacitor://localhost`)
- `require_valid_user = true` — ingen anonym åtkomst

CouchDB:s bindning till `127.0.0.1` hanteras av Docker port-mappningen (`127.0.0.1:5984:5984`), inte av `bind_address` i local.ini.

Filen är monterad read-only in i containern.

---

## Vaultstruktur

Varje hushållsmedlem har en privat vault. Det finns även en delad vault. Se `CLAUDE.local.md` för faktiska vault-namn, databasnamn och användarnamn.

Principen:

- Privata vaults: bara den enskilde användaren har åtkomst
- Delad vault: alla berörda användare har åtkomst

Behörigheter sätts via CouchDB:s `_security`-dokument per databas.

---

## Scripts

| Script | Syfte | Körs |
| --- | --- | --- |
| `scripts/init-couchdb.sh` | Laddar ned och kör CouchDB-init från LiveSync-projektet | En gång vid installation |
| `scripts/setup-users.sh` | Skapar CouchDB-användare och databaser | En gång vid installation |
| `scripts/compact-databases.sh` | Komprimerar CouchDB-databaser | Periodiskt (cron) |

Alla scripts läser credentials från `config/.env`. Credentials skickas till curl via en temporär config-fil (syns inte i process-listan).

`init-couchdb.sh` laddar ned ett externt script och frågar om bekräftelse innan det körs — granska det innan du svarar ja.

---

## Miljövariabler (config/.env)

```
COUCHDB_ADMIN_USER=...
COUCHDB_ADMIN_PASSWORD=...
# En rad per vault-användare, t.ex.:
# ALICE_PASSWORD=...
# BOB_PASSWORD=...
CLOUDFLARE_TUNNEL_TOKEN=...
```

`.env` är i `.gitignore` — pushas aldrig till GitHub. Kopiera `config/.env.example` och fyll i.

---

## Vanliga förändringar

**Lägga till ett nytt vault:**

1. Lägg till användare och databas i `scripts/setup-users.sh`
2. Kör `setup-users.sh` igen
3. Generera ny Setup URI och dela med användaren (se `docs/5-sharing.md`)

**Byta lösenord:**

1. Uppdatera `config/.env`
2. Kör `docker compose down && docker compose up -d`
3. Uppdatera Setup URI i Obsidian på alla berörda enheter

**Flytta till ny NAS:**

1. Kopiera CouchDB-datavolymen
2. Kopiera `config/`-mappen (inkl. `.env`)
3. Kör `docker compose up -d` på nya NAS:en
4. Uppdatera Cloudflare Tunnel med ny `cloudflared`-container

---

## Vad som INTE ändras utan genomtänkt beslut

- `127.0.0.1:5984:5984` port-mappningen (säkerhetskritisk — håller CouchDB av hosten)
- `network_mode: host` ska **inte** återinföras för cloudflared
- `require_valid_user` i `local.ini` (säkerhetskritiskt)
- Cloudflare Tunnel-token (regenerera i Zero Trust-dashboarden vid behov)
- Databasnamn (LiveSync-konfigurationen på alla enheter måste uppdateras om dessa ändras)
