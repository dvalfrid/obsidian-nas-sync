# 4. Obsidian LiveSync — plugin on every device

You configure LiveSync once per vault, on your first device. After that, a **Setup URI** lets you quickly configure additional devices.

---

## Install the plugin (all devices)

1. Open Obsidian → **Settings → Community plugins**
2. Turn off Safe mode if it's on
3. Click **Browse**
4. Search for `Self-hosted LiveSync`
5. Install and enable it

---

## A private vault (e.g. alice's)

### First device (Windows/Mac)

1. Create or open a vault in Obsidian
2. Open **LiveSync settings** (the plugin icon, or Settings → Self-hosted LiveSync)
3. Go to the **Setup** tab
4. Choose **"Open setup wizard"**
5. Choose **"Set up manually"**
6. Fill in:

| Field | Value |
|---|---|
| URI | `https://<your-subdomain>` |
| Username | `alice` |
| Password | alice's password |
| Database | `vault-alice` |

7. Press **Test** — should show green
8. Press **Next**
9. Choose a sync mode: **LiveSync** (recommended — real-time sync)
10. Enable **End-to-end encryption** → choose a passphrase and save it securely
11. Press **Apply**

> **Save your passphrase!** Without it you can't read your encrypted notes on a new device.

### Additional devices (Windows, Mac, iOS)

1. On the already-configured device: LiveSync settings → **"Copy setup URI"**
2. You get an encrypted URI string — copy it
3. On the new device: install LiveSync → **"Connect with setup URI"**
4. Paste the URI and enter your passphrase
5. Sync starts automatically

---

## Another private vault (e.g. bob's)

Same process as above, with bob's credentials:

| Field | Value |
|---|---|
| URI | `https://<your-subdomain>` |
| Username | `bob` |
| Password | bob's password |
| Database | `vault-bob` |

bob generates their own Setup URI for their devices.

---

## The shared vault

Everyone installs a **separate** Obsidian vault (Obsidian supports multiple vaults) and configures LiveSync with:

| Field | Value |
|---|---|
| URI | `https://<your-subdomain>` |
| Username | `shared-user` |
| Password | the shared password |
| Database | `vault-shared` |

> **Note:** Use the **same passphrase** for the shared vault on every member's devices — otherwise they can't read each other's notes.

**Recommended:** one person configures the shared vault on their first device and generates a Setup URI. The others use that URI to configure the shared vault on their own devices — that way everyone automatically shares the same encryption settings.

---

## iOS-specific notes

LiveSync works fully on iOS via the Obsidian app. HTTPS via the Cloudflare Tunnel is a requirement (which you already have).

1. Install **Obsidian** from the App Store
2. Create a new vault (local storage)
3. Install the LiveSync plugin (Community plugins in the iOS app)
4. Use the Setup URI from one of your other devices
5. Sync starts right away

---

## Sync modes explained

| Mode | Description | Good for |
|---|---|---|
| **LiveSync** | Real-time — changes propagate immediately | Active use across multiple devices |
| **Periodic** | Syncs every X minutes | Lower battery use on mobile |
| **On events** | Syncs when a file is opened/closed | A compromise |

---

## Next step

→ [5-sharing.md](5-sharing.md)
