# 3. CouchDB — Användare och databaser

`setup-users.sh` sköter det mesta automatiskt. Det här dokumentet förklarar vad som skapades och hur du verifierar det.

---

## Vad som skapas

### Användare

| Användare | Vault | Lösenord (källa) |
| --- | --- | --- |
| `admin` | Administration | `COUCHDB_ADMIN_PASSWORD` i `.env` |
| `alice` (USER1_NAME) | vault-alice (privat) | `USER1_PASSWORD` i `.env` |
| `bob` (USER2_NAME) | vault-bob (privat) | `USER2_PASSWORD` i `.env` |
| `shared-user` | vault-shared (delad) | `SHARED_PASSWORD` i `.env` |

> Exempelnamnen ovan (`alice`, `bob`) är platshållare. De faktiska namnen definieras i `ANPASSA HÄR`-blocket i `scripts/setup-users.sh`.

### Databaser och behörigheter

| Databas | Läs/skriv | Admin |
| --- | --- | --- |
| `vault-alice` | alice | (ingen, bara CouchDB-admin) |
| `vault-bob` | bob | (ingen, bara CouchDB-admin) |
| `vault-shared` | alice, bob, shared-user | (ingen, bara CouchDB-admin) |

Privata vaults är isolerade — användare kan inte komma åt varandras vaults.

---

## Vad du behöver anpassa

Innan du kör `setup-users.sh` — redigera `ANPASSA HÄR`-blocket i toppen av scriptet:

```bash
USER1_NAME="alice"       # ändra till ditt faktiska användarnamn
USER1_DB="vault-alice"   # ändra till ditt faktiska databasnamn

USER2_NAME="bob"
USER2_DB="vault-bob"

SHARED_NAME="shared-user"
SHARED_DB="vault-shared"
SHARED_MEMBERS=("$USER1_NAME" "$USER2_NAME" "$SHARED_NAME")
```

Och lägg till matchande lösenord i `config/.env`:

```env
USER1_PASSWORD=starkt-lösenord-här
USER2_PASSWORD=starkt-lösenord-här
SHARED_PASSWORD=starkt-lösenord-här
```

Samma sak för `scripts/compact-databases.sh` — uppdatera `DATABASES`-listan där med dina faktiska databasnamn.

---

## Verifiera via Fauxton (webb-UI)

Öppna CouchDB-admin lokalt på NAS:en:

```
http://localhost:5984/_utils/
```

Logga in med admin-credentials och kontrollera:

- **Databases**: ska visa dina vaults
- **_users**: ska visa alla vault-användare

> `/_utils` är blockerad externt via Cloudflare WAF (se `docs/2-cloudflare-tunnel.md`).

---

## Verifiera via curl

```bash
# Lista databaser (som admin)
curl -u admin:ADMIN_LÖSENORD https://<din-subdomän>/_all_dbs

# Testa att user1 kan nå sin vault
curl -u alice:USER1_LÖSENORD https://<din-subdomän>/vault-alice

# Testa att user1 INTE kan nå user2:s vault
curl -u alice:USER1_LÖSENORD https://<din-subdomän>/vault-bob
# Förväntat: {"error":"unauthorized",...}

# Testa att user2 kan nå shared
curl -u bob:USER2_LÖSENORD https://<din-subdomän>/vault-shared
# Förväntat: {"db_name":"vault-shared",...}
```

---

## Lägga till fler vaults senare

Lägg till i `ANPASSA HÄR`-blocket i `setup-users.sh` och kör scriptet igen:

```bash
# I config/.env
USER3_PASSWORD=starkt-lösenord-här

# I scripts/setup-users.sh (ANPASSA HÄR-blocket)
USER3_NAME="carol"
USER3_DB="vault-carol"
```

Lägg sedan till `create_user`, `create_database` och `set_db_permissions`-anrop i scriptet, och uppdatera `DATABASES`-listan i `compact-databases.sh`.

---

## Nästa steg

→ [4-obsidian-plugin.md](4-obsidian-plugin.md)
