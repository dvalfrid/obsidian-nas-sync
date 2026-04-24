# 3. CouchDB — Användare och databaser

`setup-users.sh` sköter det mesta automatiskt. Det här dokumentet förklarar vad som skapades och hur du verifierar det.

---

## Vad som skapades

### Användare

| Användare | Vault | Lösenord (källa) |
|---|---|---|
| `admin` | Administration | `COUCHDB_ADMIN_PASSWORD` i `.env` |
| `daniel` | vault-daniel (privat) | `DANIEL_PASSWORD` i `.env` |
| `linda` | vault-linda (privat) | `LINDA_PASSWORD` i `.env` |
| `shared-user` | vault-shared (delad) | `SHARED_PASSWORD` i `.env` |

### Databaser och behörigheter

| Databas | Läs/skriv | Admin |
|---|---|---|
| `vault-daniel` | daniel | (ingen, bara CouchDB-admin) |
| `vault-linda` | linda | (ingen, bara CouchDB-admin) |
| `vault-shared` | daniel, linda, shared-user | (ingen, bara CouchDB-admin) |

`daniel` och `linda` kan **inte** komma åt varandras privata vaults. Båda kan komma åt `vault-shared`.

---

## Verifiera via Fauxton (webb-UI)

Öppna CouchDB-admin lokalt på NAS:en:

```
http://localhost:5984/_utils/
```

Eller via Cloudflare Tunnel (kräver inloggning):

```
https://obsidian.valfridsson.se/_utils/
```

Logga in med admin-credentials och kontrollera:
- **Databases**: ska visa `vault-daniel`, `vault-linda`, `vault-shared`
- **_users** → Verifiera att daniel, linda och shared-user finns

---

## Verifiera via curl

```bash
# Lista databaser (som admin)
curl -u admin:ADMIN_LÖSENORD https://obsidian.valfridsson.se/_all_dbs

# Testa att daniel kan nå sin vault
curl -u daniel:DANIEL_LÖSENORD https://obsidian.valfridsson.se/vault-daniel

# Testa att daniel INTE kan nå lindas vault
curl -u daniel:DANIEL_LÖSENORD https://obsidian.valfridsson.se/vault-linda
# Förväntat: {"error":"unauthorized",...}

# Testa att linda kan nå shared
curl -u linda:LINDA_LÖSENORD https://obsidian.valfridsson.se/vault-shared
# Förväntat: {"db_name":"vault-shared",...}
```

---

## Lägga till fler vaults senare

Om du vill lägga till en tredje person, redigera `setup-users.sh`:

```bash
# Lägg till i .env
NYA_PERSON_PASSWORD=...

# Lägg till i setup-users.sh och kör igen
create_user "nyaperson" "$NYA_PERSON_PASSWORD"
create_database "vault-nyaperson"
set_db_permissions "vault-nyaperson" "nyaperson"
```

---

## Nästa steg

→ [4-obsidian-plugin.md](4-obsidian-plugin.md)
