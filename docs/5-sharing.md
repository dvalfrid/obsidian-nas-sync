# 5. Dela vault med Linda

---

## Hur delningen fungerar

```
Daniel (vault-shared) ──┐
                         ├──► CouchDB: vault-shared ◄──┐
Linda  (vault-shared) ──┘                               │
                                                        │
                    Båda ser samma innehåll i realtid ──┘
```

Den delade vaulten fungerar som en gemensam anteckningsbok. Allt Daniel skriver syns hos Linda och vice versa — i realtid (LiveSync-läge) eller med kort fördröjning (Periodic-läge).

---

## Dela Setup URI med Linda

Det enklaste sättet att få Linda igång på shared-vaulten:

### 1. Daniel genererar Setup URI

På Daniels enhet, i shared-vaultens LiveSync-inställningar:
- Gå till **Setup → Copy setup URI**
- Du får en lång krypterad sträng

### 2. Skicka URI + passphrase till Linda

Dela via ett säkert medium (t.ex. AirDrop, Signal, eller fysiskt):
- Setup URI:n
- Den gemensamma passphrases för shared-vaulten

> **Viktigt:** Dela inte via okrypterad e-post eller SMS.

### 3. Linda konfigurerar sin enhet

1. Installera Obsidian och skapa en ny (tom) vault
2. Installera LiveSync-pluginet
3. LiveSync-inställningar → **"Connect with setup URI"**
4. Klistra in URI:n
5. Ange passphrases
6. Klart — vaulten synkas ner automatiskt

---

## Hantera konflikter

Om Daniel och Linda redigerar **samma anteckning samtidigt** (på offline-enheter som sedan synkar) hanterar LiveSync det automatiskt:

- LiveSync **detekterar konflikten** och sparar båda versionerna
- En notis visas i Obsidian
- Du väljer manuellt vilken version som gäller, eller slår ihop dem

Det händer sällan om ni har bra nätverksuppkoppling — LiveSync synkar i realtid och förhindrar de flesta konflikter.

---

## Tips för delad vault

- Skapa en tydlig mappstruktur (`Daniel/`, `Linda/`, `Gemensamt/`)
- Undvik att redigera exakt samma fil samtidigt
- Använd Obsidians inbyggda taggar för att organisera gemensamma anteckningar

---

## Vad som INTE delas

- Daniels `vault-daniel` — bara Daniel kan se och redigera
- Lindas `vault-linda` — bara Linda kan se och redigera
- Plugin-inställningar och teman är separata per vault

---

## Nästa steg

→ [6-maintenance.md](6-maintenance.md)
