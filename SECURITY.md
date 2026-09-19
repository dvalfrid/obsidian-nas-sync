# Security Policy

## Supported versions

Only the latest release receives security fixes.

| Version        | Supported |
| -------------- | --------- |
| Latest release | ✅        |
| Older versions | ❌        |

## Reporting a vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Use one of these private channels:

- **GitHub private vulnerability reporting** —
  [Report a vulnerability](https://github.com/dvalfrid/obsidian-nas-sync/security/advisories/new)
  (preferred)
- **Email** — daniel@valfridsson.net

Include as much of the following as possible:

- Type of issue (e.g. credential leakage, authentication bypass,
  container/network misconfiguration)
- Steps to reproduce
- Affected version
- Potential impact

## Response timeline

|                 | Target                                      |
| --------------- | -------------------------------------------- |
| Acknowledgement | Within 7 days                               |
| Patch release   | Within 14 days of a confirmed vulnerability |

## Scope and threat model

This project stores real Obsidian notes for every user who syncs to it, gated
entirely by CouchDB credentials and a Cloudflare Tunnel. Security issues most
relevant here:

- **CouchDB admin credentials** (`COUCHDB_ADMIN_USER`/`COUCHDB_ADMIN_PASSWORD`)
  — the highest-value credential in the system. Full control over every
  database and user; compromise means total read/write/delete access across
  *all* vaults, including ones a given person was never granted access to,
  plus the ability to create or delete users. `setup-users.sh` and
  `compact-databases.sh` write these to a `chmod 600` temp file for curl
  rather than passing them on the command line or embedding them in a URL,
  specifically so they don't leak into the process list (`ps aux`) or logs.
- **Per-user CouchDB credentials** (`USER1_PASSWORD`, `USER2_PASSWORD`,
  `SHARED_PASSWORD`, etc.) — scoped to exactly the vault(s) that user is
  listed as a `_security.members` name for (see `scripts/setup-users.sh`).
  Compromising one user's password does **not** grant access to another
  private vault by design — but it does grant full read/write/delete of
  every vault (including shared ones) that user belongs to, so a shared
  vault's member list is only as trustworthy as its least-secured member's
  password.
- **Cloudflare Tunnel token** (`CLOUDFLARE_TUNNEL_TOKEN`) — lets whoever holds
  it run their own `cloudflared` connector impersonating this tunnel,
  potentially intercepting or redirecting traffic bound for the public
  hostname. It does not by itself grant CouchDB access (a valid CouchDB
  username/password is still required over that connection), but should be
  rotated immediately in the Cloudflare Zero Trust dashboard if leaked.
- **Network isolation** — CouchDB is only reachable from the host on
  `127.0.0.1:5984` (never a non-loopback address), and `cloudflared` runs in
  a dedicated Docker bridge network (`couchdb-internal`) rather than
  `network_mode: host`, so a compromised `cloudflared` container can reach
  only the CouchDB container, not the rest of the host's network. Both of
  these are load-bearing invariants — see CLAUDE.md's "what not to change"
  list.
- **`require_valid_user = true`** (`config/couchdb/local.ini`) — another
  load-bearing invariant. Disabling it permits fully anonymous read/write
  access to every database. This is the single most security-critical line
  in the config.
- **The LiveSync init script** (`scripts/init-couchdb.sh`) downloads a
  third-party script from the upstream `obsidian-livesync` project at
  runtime and asks for confirmation before executing it, rather than piping
  it straight into `bash`. Review the downloaded script if you don't fully
  trust the upstream project or your network path to GitHub.
- **Data at rest** — the CouchDB data volume holds unencrypted data by
  default; anyone with filesystem or backup access to that path has
  plaintext access to every vault's contents unless LiveSync's optional
  per-vault end-to-end-encryption passphrase is enabled (recommended in the
  docs, not enforced by the stack itself).

Out of scope: an already-compromised Docker host, NAS admin account, or
Cloudflare account; running with the CouchDB port mapping changed to a
non-loopback address (explicitly unsupported).
