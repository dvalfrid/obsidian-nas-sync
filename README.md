# Obsidian NAS Sync — Self-hosted LiveSync med TerraMaster & Cloudflare

Komplett self-hosted synklösning för Obsidian med tre separata vaults:

- **Daniel** — privat vault
- **Linda** — privat vault  
- **Shared** — delad familjevault

Synken sker via [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) och en CouchDB-instans på din TerraMaster F4-424 Pro, exponerad säkert via Cloudflare Tunnel (HTTPS, ingen öppen port i routern).

---

## Arkitektur

```
[Obsidian: Daniel]  ──┐
[Obsidian: Linda]   ──┤── HTTPS ──► obsidian.valfridsson.se ──► Cloudflare Tunnel ──► CouchDB på NAS
[Obsidian: Shared]  ──┘
        (alla enheter: Windows, macOS, iOS)
```

**Tre databaser i CouchDB:**
- `vault-daniel`
- `vault-linda`
- `vault-shared`

---

## Förkrav

- TerraMaster F4-424 Pro med TOS 5 eller TOS 6
- Docker och Portainer aktiverat på NAS:en
- SSH-åtkomst till NAS:en
- Cloudflare-konto med `valfridsson.se` konfigurerat
- Obsidian installerat på alla enheter

---

## Dokumentation

| Fil | Innehåll |
|---|---|
| [docs/1-nas-setup.md](docs/1-nas-setup.md) | CouchDB på NAS via Docker |
| [docs/2-cloudflare-tunnel.md](docs/2-cloudflare-tunnel.md) | Cloudflare Tunnel mot NAS |
| [docs/3-couchdb-users.md](docs/3-couchdb-users.md) | Användare och databaser i CouchDB |
| [docs/4-obsidian-plugin.md](docs/4-obsidian-plugin.md) | LiveSync-plugin på varje enhet |
| [docs/5-sharing.md](docs/5-sharing.md) | Dela vault med Linda |
| [docs/6-maintenance.md](docs/6-maintenance.md) | Backup, underhåll, felsökning |

---

## Snabbstart

```bash
# Klona repot på din NAS (via SSH)
git clone https://github.com/DITT_REPO/obsidian-nas-sync
cd obsidian-nas-sync

# Kopiera och redigera miljövariabler
cp config/.env.example config/.env
nano config/.env

# Starta CouchDB
docker compose -f config/docker-compose.yml up -d

# Initiera CouchDB
./scripts/init-couchdb.sh

# Skapa användare och databaser
./scripts/setup-users.sh
```

Se fullständiga instruktioner i [docs/1-nas-setup.md](docs/1-nas-setup.md).

---

## Säkerhet

- Inga portar öppnade i routern — all trafik via Cloudflare Tunnel
- HTTPS med giltigt certifikat (automatiskt via Cloudflare)
- Separata CouchDB-användare per person — Linda kan inte nå Daniels vault
- Gemensamt konto för shared vault
- End-to-end-kryptering i LiveSync (valfritt men rekommenderas)
- CouchDB lyssnar inte på extern IP — bara localhost, Cloudflared når den inifrån

---

## Filstruktur

```
obsidian-nas-sync/
├── README.md
├── CLAUDE.md                        ← Instruktioner för AI-assistenten
├── config/
│   ├── .env.example                 ← Mall för miljövariabler
│   ├── docker-compose.yml           ← CouchDB + Cloudflared
│   └── couchdb/
│       └── local.ini                ← CouchDB-konfiguration
├── scripts/
│   ├── init-couchdb.sh              ← Initierar CouchDB-inställningar
│   ├── setup-users.sh               ← Skapar användare och databaser
│   └── compact-databases.sh         ← Komprimerar databaser (underhåll)
└── docs/
    ├── 1-nas-setup.md
    ├── 2-cloudflare-tunnel.md
    ├── 3-couchdb-users.md
    ├── 4-obsidian-plugin.md
    ├── 5-sharing.md
    └── 6-maintenance.md
```
