# patch-proxmox-nosub

Removes the "No valid subscription" warning dialog from the Proxmox VE web interface by neutralizing the subscription check in `proxmoxlib.js`.

> ⚠️ **For personal and educational use only.** This modifies a core Proxmox file and will be overwritten by updates to the `proxmox-widget-toolkit` package. Reapply after upgrades.

---

## How It Works

Rather than deleting code blocks (which risks breaking other UI dialogs), this script neutralizes the condition that triggers the warning:

```javascript
// Before
res.data.status.toLowerCase() !== 'active'

// After
false
```

This leaves the surrounding JavaScript structure completely intact. All other dialogs — confirmations, notifications, WebAuthn prompts — are unaffected.

---

## Prerequisites

- Proxmox VE host with root access
- `proxmox-widget-toolkit` installed (standard on all PVE installs)
- Tested on Proxmox VE 7.x, 8.x, and 9.x

---

## Installation

SSH into your Proxmox host as root and clone the repo:

```bash
git clone https://github.com/leeroy4000/patch-proxmox-nosub.git
cd patch-proxmox-nosub
chmod +x patch-proxmox-nosub.sh
```

Optionally, install it globally (the command is then `patch-proxmox-nosub.sh`, extension included):

```bash
install -m 755 patch-proxmox-nosub.sh /usr/local/bin/patch-proxmox-nosub.sh
```

---

## Usage

### Apply the patch

```bash
./patch-proxmox-nosub.sh patch
```

The script will:
1. Check that the subscription check is still present (if not, it exits without changing anything)
2. Save a backup of the current, unpatched `proxmoxlib.js` at `proxmoxlib.js.bak` (refreshed on every patch, so it always matches the installed package version)
3. Neutralize the subscription check
4. Restart `pveproxy` so changes take effect immediately

Refresh your browser — the nag dialog will be gone.

### Restore the original file

```bash
./patch-proxmox-nosub.sh restore
```

Copies the backup back into place and restarts `pveproxy`. The backup is the file as it was just before the last patch, so after a package update, patch again before relying on `restore`.

---

## Example Output

```
  Proxmox No-Subscription Patch
  ==============================

[INFO]  Target: /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
[OK]    Backup of current unpatched file saved at ...proxmoxlib.js.bak
[OK]    Subscription check neutralized.
[INFO]  Restarting pveproxy...
[OK]    pveproxy restarted. Changes are live — refresh your browser.
```

---

## After Proxmox Updates

Updates to `proxmox-widget-toolkit` will overwrite `proxmoxlib.js` and revert the patch. When this happens, simply rerun:

```bash
patch-proxmox-nosub.sh patch
```

(or `./patch-proxmox-nosub.sh patch` from the cloned directory). Running the script with no argument only prints the usage text and changes nothing.

You can check if the patch is still active by running the script — it will warn you if the pattern is not found or already neutralized.

---

## License

MIT License — free to fork, adapt, and improve.
