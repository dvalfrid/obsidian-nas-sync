# CLAUDE.md — Kontext för AI-assistenten

Det här dokumentet beskriver projektets arkitektur, designbeslut och konventioner så att en AI-assistent kan hjälpa till med ändringar utan att behöva ställa grundläggande frågor.

---

## Vad projektet gör

Self-hosted Obsidian-synklösning för ett hushåll (Daniel + Linda) på en **TerraMaster F4-424 Pro NAS**.

- Synkmotor: **CouchDB** (via Docker) + **Self-hosted LiveSync** (Obsidian-plugin)
- Exponering: **Cloudflare Tunnel** → `obsidian.valfridsson.se` (ingen öppen port i router)
- Tre separata CouchDB-databaser, en per vault

---

## Miljö och hårdvara

| Komponent | Detalj |
|---|---|
| NAS | TerraMaster F4-424 Pro |
| NAS OS | TOS 5 (uppgraderbar till TOS 6) |
| Container-runtime | Docker + Portainer (inbyggt i TOS) |
| Domän | valfridsson.se (Cloudflare-hanterad) |
| Befintliga subdomäner | `calendar.valfridsson.se`, `bluebubble.valfridsson.se` → Mac Pro |
| Ny subdomän | `obsidian.valfridsson.se` → NAS (separat Cloudflare Tunnel) |

---

## Vaultstruktur

| Vault | CouchDB-databas | CouchDB-användare | Vem har åtkomst |
|---|---|---|---|
| Daniel privat | `vault-daniel` | `daniel` | Bara Daniel |
| Linda privat | `vault-linda` | `linda` | Bara Linda |
| Familj/delad | `vault-shared` | `shared-user` | Både Daniel och Linda |

Lösenord lagras i `config/.env` (ingår ej i git — se `.gitignore`).

---

## Docker Compose-filer

`config/docker-compose.yml` startar två containers:
1. `couchdb` — databasen, lyssnar bara på `127.0.0.1:5984`
2. `cloudflared` — Cloudflare Tunnel-klienten, når CouchDB via `http://localhost:5984`

**Viktigt:** CouchDB är konfigurerad att bara binda till `127.0.0.1`, inte `0.0.0.0`. All extern trafik går via Cloudflare Tunnel. Ändra inte `bind_address` utan att förstå säkerhetsimplikationerna.

---

## CouchDB-konfiguration

`config/couchdb/local.ini` innehåller:
- `bind_address = 127.0.0.1` (säkerhetskritiskt)
- CORS-inställningar för Obsidian-appen (app://obsidian.md, capacitor://localhost)
- `require_valid_user = true` — ingen anonym åtkomst

Filen är monterad read-only in i containern.

---

## Scripts

| Script | Syfte | Körs |
|---|---|---|
| `scripts/init-couchdb.sh` | Kör CouchDB-init från LiveSync-projektet | En gång vid installation |
| `scripts/setup-users.sh` | Skapar CouchDB-användare och databaser | En gång vid installation |
| `scripts/compact-databases.sh` | Komprimerar CouchDB-databaser | Periodiskt (cron) |

Alla scripts läser credentials från `config/.env`.

---

## Miljövariabler (config/.env)

```
COUCHDB_ADMIN_USER=admin
COUCHDB_ADMIN_PASSWORD=...
DANIEL_PASSWORD=...
LINDA_PASSWORD=...
SHARED_PASSWORD=...
CLOUDFLARE_TUNNEL_TOKEN=...
```

`.env` är i `.gitignore` — pushas aldrig till GitHub.

---

## Vanliga förändringar

**Lägga till ett nytt vault:**
1. Lägg till användare i `scripts/setup-users.sh`
2. Kör `setup-users.sh` igen
3. Generera ny Setup URI och dela med användaren (se `docs/5-sharing.md`)

**Byta lösenord:**
1. Uppdatera `config/.env`
2. Kör `docker compose down && docker compose up -d`
3. Uppdatera Setup URI i Obsidian på alla berörda enheter

**Flytta till ny NAS:**
1. Kopiera volymen `/volume1/docker/couchdb-obsidian/data`
2. Kopiera `config/`-mappen
3. Kör `docker compose up -d` på nya NAS:en
4. Uppdatera Cloudflare Tunnel med ny `cloudflared`-container

---

## Vad som INTE ändras utan genomtänkt beslut

- `bind_address` i `local.ini` (säkerhetskritiskt)
- `require_valid_user` i `local.ini` (säkerhetskritiskt)
- Cloudflare Tunnel-token (regenerera i Zero Trust-dashboarden vid behov)
- Databasnamn (LiveSync-konfigurationen på alla enheter måste uppdateras om dessa ändras)
