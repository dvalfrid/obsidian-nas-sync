# Obsidian NAS Sync — self-hosted LiveSync with Docker & Cloudflare

A complete self-hosted sync solution for Obsidian with any number of vaults — for example, three:

- **A private vault** for one person
- **A private vault** for another person
- **A shared vault** for both

Sync happens via [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) and a CouchDB instance on your own NAS, exposed securely via a Cloudflare Tunnel (HTTPS, no open port on your router).

---

## Architecture

```
[Obsidian: user 1]  ──┐
[Obsidian: user 2]  ──┤── HTTPS ──► <your-subdomain> ──► Cloudflare Tunnel ──► CouchDB on your NAS
[Obsidian: shared]  ──┘
        (any device: Windows, macOS, iOS)
```

**Three databases in CouchDB by default** (the example used throughout this repo's scripts and docs):
- `vault-alice`
- `vault-bob`
- `vault-shared`

Rename these to your own vaults — see the "CUSTOMIZE HERE" block in `scripts/setup-users.sh`.

---

## Prerequisites

- A NAS or Linux host with Docker (and, on a NAS, its GUI like Portainer) enabled
- SSH access to that host
- A Cloudflare account with your own domain configured
- Obsidian installed on every device

---

## Documentation

| File | Contents |
|---|---|
| [docs/1-nas-setup.md](docs/1-nas-setup.md) | CouchDB on your NAS via Docker |
| [docs/2-cloudflare-tunnel.md](docs/2-cloudflare-tunnel.md) | Cloudflare Tunnel to your NAS |
| [docs/3-couchdb-users.md](docs/3-couchdb-users.md) | Users and databases in CouchDB |
| [docs/4-obsidian-plugin.md](docs/4-obsidian-plugin.md) | LiveSync plugin on every device |
| [docs/5-sharing.md](docs/5-sharing.md) | Sharing a vault between multiple people |
| [docs/6-maintenance.md](docs/6-maintenance.md) | Backup, maintenance, troubleshooting |

---

## Quick start

```bash
# Clone the repo onto your NAS (via SSH)
git clone https://github.com/dvalfrid/obsidian-nas-sync
cd obsidian-nas-sync

# Copy and edit environment variables
cp config/.env.example config/.env
nano config/.env

# Start CouchDB and cloudflared
cd config
docker compose up -d
cd ..

# Initialize CouchDB for LiveSync
./scripts/init-couchdb.sh

# Create users and databases
./scripts/setup-users.sh
```

Before the last step, edit the "CUSTOMIZE HERE" block at the top of `scripts/setup-users.sh` (and the `DATABASES` list in `scripts/compact-databases.sh`) to use your own usernames and database names instead of the `alice`/`bob`/`shared-user` example.

See the full walkthrough in [docs/1-nas-setup.md](docs/1-nas-setup.md).

---

## Security

- No ports opened on your router — all traffic goes through the Cloudflare Tunnel
- HTTPS with a valid certificate (automatic via Cloudflare)
- Separate CouchDB user per person — one private vault can't be reached by another person's user
- A shared account for the shared vault
- End-to-end encryption in LiveSync (optional but recommended)
- CouchDB doesn't listen on an external IP — only localhost; cloudflared reaches it from inside its own Docker network

---

## File structure

```
obsidian-nas-sync/
├── README.md
├── CLAUDE.md                        ← Context for AI assistants
├── LICENSE
├── SECURITY.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── config/
│   ├── .env.example                 ← Template for environment variables
│   ├── docker-compose.yml           ← CouchDB + cloudflared
│   └── couchdb/
│       └── local.ini                ← CouchDB configuration
├── scripts/
│   ├── init-couchdb.sh              ← Initializes CouchDB settings
│   ├── setup-users.sh               ← Creates users and databases
│   └── compact-databases.sh         ← Compacts databases (maintenance)
└── docs/
    ├── 1-nas-setup.md
    ├── 2-cloudflare-tunnel.md
    ├── 3-couchdb-users.md
    ├── 4-obsidian-plugin.md
    ├── 5-sharing.md
    └── 6-maintenance.md
```

---

## License

This repo's own code (scripts, Docker Compose file, docs) is [MIT-licensed](LICENSE). It orchestrates, but does not bundle, third-party components that keep their own licenses: [CouchDB](https://couchdb.apache.org/) (Apache 2.0), [cloudflared](https://github.com/cloudflare/cloudflared) (Apache 2.0), and the [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) Obsidian plugin (its own license).

See [SECURITY.md](SECURITY.md) for the security policy and [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute.
