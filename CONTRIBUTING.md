# Contributing to obsidian-nas-sync

This started as a personal tool and is shared publicly as-is, but issues and
pull requests are welcome.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). Be
respectful and constructive, assume good faith, keep discussion on the code.

## Prerequisites

- Docker Engine + Compose v2
- A NAS or Linux host that can run containers
- `bash` and `curl` (used by the scripts)

## Getting started

```bash
git clone https://github.com/dvalfrid/obsidian-nas-sync
cd obsidian-nas-sync
cp config/.env.example config/.env
# fill in config/.env — see README "Quick start"
cd config && docker compose up -d
cd ..
./scripts/init-couchdb.sh
./scripts/setup-users.sh
```

## Development workflow

1. **Open an issue first** for anything beyond a trivial fix — describe the
   bug (repro steps, expected behavior) or the feature (what changes for the
   user and why).
2. **Branch** from `main`.
3. **Implement** the change.
4. **Verify it actually works** — there are no automated tests here. At
   minimum: `bash -n scripts/*.sh` for syntax, `docker compose config` to
   validate the Compose file, and actually bringing the stack up and running
   `setup-users.sh`/`compact-databases.sh` against a real (or throwaway)
   CouchDB instance.
5. Update **README.md** for anything user-facing, and **CLAUDE.md** for
   anything an AI assistant or future maintainer would need to know to work
   on the project safely (invariants, gotchas, architecture).
6. Open a pull request.

## Commit message format

Clear, descriptive commit messages are appreciated, optionally in
[Conventional Commits](https://www.conventionalcommits.org/) style
(`type: summary`). There is no CI or release automation here that depends
on this format — it's a style preference, not an enforced mechanism.

## Project layout

See the README's [File structure](README.md#file-structure) section, and
CLAUDE.md for the architecture and the invariants that keep the security
model (localhost-only CouchDB, network-isolated cloudflared,
tunnel-mediated access) intact.
