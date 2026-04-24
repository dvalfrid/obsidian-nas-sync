# 4. Obsidian LiveSync — Plugin på varje enhet

Du konfigurerar LiveSync en gång per vault, på din första enhet. Sedan används en **Setup URI** för att snabbt konfigurera övriga enheter.

---

## Installera pluginet (alla enheter)

1. Öppna Obsidian → **Settings → Community plugins**
2. Stäng av Safe mode om det är på
3. Klicka **Browse**
4. Sök på `Self-hosted LiveSync`
5. Installera och aktivera

---

## Daniels privata vault

### Första enheten (Windows/Mac)

1. Skapa eller öppna en vault i Obsidian
2. Öppna **LiveSync-inställningar** (plugin-ikonen eller Settings → Self-hosted LiveSync)
3. Gå till fliken **Setup**
4. Välj **"Open setup wizard"**
5. Välj **"Set up manually"**
6. Fyll i:

| Fält | Värde |
|---|---|
| URI | `https://obsidian.valfridsson.se` |
| Username | `daniel` |
| Password | Ditt Daniel-lösenord |
| Database | `vault-daniel` |

7. Tryck **Test** — ska visa grönt
8. Tryck **Next**
9. Välj sync-läge: **LiveSync** (rekommenderas — realtidssynk)
10. Aktivera **End-to-end encryption** → välj en passphrase och spara den säkert
11. Tryck **Apply**

> **Spara din passphrase!** Utan den kan du inte läsa dina krypterade anteckningar på en ny enhet.

### Ytterligare enheter (Windows, Mac, iOS)

1. På den konfigurerade enheten: LiveSync-inställningar → **"Copy setup URI"**
2. Du får en krypterad URI-sträng — kopiera den
3. På den nya enheten: installera LiveSync → **"Connect with setup URI"**
4. Klistra in URI:n och ange din passphrase
5. Synk startar automatiskt

---

## Lindas privata vault

Samma process som ovan, men med Lindas credentials:

| Fält | Värde |
|---|---|
| URI | `https://obsidian.valfridsson.se` |
| Username | `linda` |
| Password | Lindas lösenord |
| Database | `vault-linda` |

Linda genererar sin egna Setup URI för sina enheter.

---

## Den delade familje-vaulten

Båda installerar ett **separat** Obsidian-vault (Obsidian stöder flera vaults) och konfigurerar LiveSync med:

| Fält | Värde |
|---|---|
| URI | `https://obsidian.valfridsson.se` |
| Username | `shared-user` |
| Password | Shared-lösenordet |
| Database | `vault-shared` |

> **OBS:** Använd **samma passphrase** för den delade vaulten på Daniels och Lindas enheter — annars kan de inte läsa varandras anteckningar.

**Rekommenderat:** Daniel konfigurerar shared-vaulten på sin första enhet och genererar Setup URI. Linda använder den URI:n för att konfigurera shared-vaulten på sina enheter. Då delar de automatiskt samma krypteringsinställningar.

---

## iOS-specifikt

LiveSync fungerar fullt ut på iOS via Obsidian-appen. HTTPS via Cloudflare Tunnel är ett krav (vilket du redan har).

1. Installera **Obsidian** från App Store
2. Skapa en ny vault (lokal lagring)
3. Installera LiveSync-pluginet (Community plugins i iOS-appen)
4. Använd Setup URI från en av dina andra enheter
5. Synk startar direkt

---

## Sync-lägen förklarat

| Läge | Beskrivning | Bra för |
|---|---|---|
| **LiveSync** | Realtid — ändringar sprids direkt | Aktiv användning på flera enheter |
| **Periodic** | Synkar var X:e minut | Lägre batterianvändning på mobil |
| **On events** | Synkar vid öppning/stängning av fil | Kompromiss |

---

## Nästa steg

→ [5-sharing.md](5-sharing.md)
