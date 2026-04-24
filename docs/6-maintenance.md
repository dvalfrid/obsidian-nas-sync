# 6. Underhåll, backup och felsökning

---

## Regelbundet underhåll

### Komprimera databaser (månadsvis)

CouchDB sparar alla revisioner av dina anteckningar. Utan komprimering växer databasfilen i onödan.

```bash
cd /volume1/obsidian-nas-sync
./scripts/compact-databases.sh
```

Eller sätt upp ett automatiskt cron-jobb via TOS (Kontrollpanel → Schemalagda uppgifter):

```
0 3 1 * * /volume1/obsidian-nas-sync/scripts/compact-databases.sh
```

(Kör kl 03:00 den 1:a varje månad)

### Uppdatera Docker-images

```bash
cd /volume1/obsidian-nas-sync/config
docker compose pull
docker compose down
docker compose up -d
```

---

## Backup

### Vad som behöver backas upp

| Vad | Var | Varför |
|---|---|---|
| CouchDB-data | `/volume1/docker/couchdb-obsidian/data/` | Alla anteckningar |
| Konfiguration | `/volume1/obsidian-nas-sync/config/.env` | Lösenord och token |
| Repo | GitHub | Allt annat |

### Backup med TerraMaster Duple Backup

TOS har inbyggd Duple Backup — konfigurera den att backa upp `/volume1/docker/couchdb-obsidian/data/` till en annan disk eller extern källa.

### Manuell backup

```bash
# Skapa en komprimerad backup av CouchDB-data
tar -czf ~/couchdb-backup-$(date +%Y%m%d).tar.gz \
  /volume1/docker/couchdb-obsidian/data/
```

> **OBS:** LiveSync håller automatiskt en fullständig lokal kopia av vaulten på varje enhet. Om NAS:en kraschar har du fortfarande alla anteckningar lokalt på din dator/telefon.

---

## Felsökning

### CouchDB svarar inte

```bash
# Kontrollera att containern kör
docker ps | grep couchdb

# Visa loggar
docker logs couchdb-obsidian --tail 50

# Starta om
docker restart couchdb-obsidian
```

### Cloudflare Tunnel är nere

```bash
# Kontrollera att containern kör
docker ps | grep cloudflared

# Visa loggar
docker logs cloudflared-nas --tail 50

# Starta om
docker restart cloudflared-nas
```

Kontrollera även i [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) → Networks → Tunnels att statusen är Healthy.

### LiveSync synkar inte

1. Kontrollera att `https://obsidian.valfridsson.se/_up` svarar
2. I Obsidian → LiveSync-inställningar → **Test** (Connection test)
3. Öppna Obsidian Developer Tools (Ctrl+Shift+I) → Console för felmeddelanden
4. Kontrollera att rätt databas och credentials används

### "Unauthorized" trots rätt lösenord

CouchDB-sessioner löper ut. Prova:
- Stäng och öppna om Obsidian
- Eller: LiveSync → Disconnect → Reconnect

### Databasen är full / prestanda är dålig

Kör `compact-databases.sh` (se ovan).

---

## Återställa efter NAS-haveri

1. Installera Docker och klona repot på ny/återställd NAS
2. Kopiera CouchDB-backup till `/volume1/docker/couchdb-obsidian/data/`
3. Återskapa `config/.env` med dina sparade credentials
4. Kör `docker compose up -d`
5. Verifiera med `curl https://obsidian.valfridsson.se/_up`

Inga ändringar behövs i Obsidian på klientenheterna — de ansluter automatiskt när servern är tillbaka.

---

## Säkerhetskontroll (kör ibland)

```bash
# Verifiera att CouchDB INTE är åtkomlig direkt (ska misslyckas)
curl http://<nas-ip>:5984/_up

# Verifiera att anonym åtkomst är blockerad
curl https://obsidian.valfridsson.se/_all_dbs
# Förväntat: {"error":"unauthorized",...}

# Verifiera att cross-user isolering fungerar
curl -u daniel:DANIEL_PASS https://obsidian.valfridsson.se/vault-linda
# Förväntat: {"error":"unauthorized",...}
```
