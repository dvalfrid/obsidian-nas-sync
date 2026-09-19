# 5. Sharing a vault between multiple people

---

## How sharing works

```
alice (vault-shared) ──┐
                        ├──► CouchDB: vault-shared ◄──┐
bob   (vault-shared) ──┘                              │
                                                       │
                 Both see the same content live ──────┘
```

The shared vault works like a joint notebook. Anything alice writes shows up for bob and vice versa — in real time (LiveSync mode) or with a short delay (Periodic mode).

---

## Sharing the Setup URI

The easiest way to get the other member started on the shared vault:

### 1. Generate a Setup URI

On one device, in the shared vault's LiveSync settings:
- Go to **Setup → Copy setup URI**
- You get a long, encrypted string

### 2. Send the URI + passphrase to the other member

Share it over a secure channel (e.g. AirDrop, Signal, or in person):
- The Setup URI
- The shared vault's common passphrase

> **Important:** Don't share these over unencrypted email or SMS.

### 3. The other member configures their device

1. Install Obsidian and create a new (empty) vault
2. Install the LiveSync plugin
3. LiveSync settings → **"Connect with setup URI"**
4. Paste the URI
5. Enter the passphrase
6. Done — the vault syncs down automatically

---

## Handling conflicts

If two members edit **the same note at the same time** (e.g. on offline devices that sync later), LiveSync handles it automatically:

- LiveSync **detects the conflict** and keeps both versions
- A notice appears in Obsidian
- You manually choose which version wins, or merge them

This happens rarely with a decent network connection — LiveSync syncs in real time and prevents most conflicts.

---

## Tips for a shared vault

- Create a clear folder structure, e.g. `Alice/`, `Bob/`, `Shared/`
- Avoid editing the exact same file at the same time
- Use Obsidian's built-in tags to organize shared notes

---

## What is NOT shared

- alice's `vault-alice` — only alice can see and edit it
- bob's `vault-bob` — only bob can see and edit it
- Plugin settings and themes — these are separate per vault

---

## Next step

→ [6-maintenance.md](6-maintenance.md)
