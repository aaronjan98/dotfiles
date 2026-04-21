# NixOS Printing

## Purpose
Enable, configure, and manage printing on NixOS. Covers initial setup, adding printers via CUPS, and managing print jobs.

---

## Step 1 — Check if CUPS is running

```
systemctl status cups
```

If the unit is not found or not running, printing is not configured. Proceed to Step 2.

---

## Step 2 — Enable printing in NixOS configuration

Add the following to `/etc/nixos/hosts/<hostname>/configuration.nix`:

```nix
# Printing
services.printing.enable = true;
services.avahi = {
  enable = true;
  nssmdns4 = true;   # enables mDNS so network printers are discoverable
  openFirewall = true;
};
```

Then rebuild:

```
sudo nixos-rebuild switch
```

Verify CUPS is now running:

```
systemctl status cups
```

---

## Step 3 — Add a printer via CUPS web interface

1. Open `http://localhost:631/` in a browser
2. Click **Administration** → **Add Printer**
3. Log in with your system username and password (e.g. `aj`)
4. Select your printer from **Discovered Network Printers** and click **Continue**
5. Set a name, click **Continue**
6. Select a driver (use your printer model if listed; otherwise **Generic PostScript Printer**)
7. Click **Add Printer**
8. Set default options (paper size: **Letter**) and click **Set Default Options**

---

## Step 4 — Print from Firefox or Okular

After adding the printer it will appear automatically in any application's print dialog.

For Okular (PDF forms):
```
nix-shell -p kdePackages.okular --run okular
```

---

## Managing print jobs

List queued jobs:
```
lpstat -o
```

Cancel a specific job (get job ID from lpstat):
```
lprm <job-id>
```

Cancel all jobs for your user:
```
lprm -
```

Check printer status:
```
lpstat -p
```

---

## Troubleshooting

**Printer not appearing in discovered list:**
- Confirm the printer is on the same network
- Check avahi is running: `systemctl status avahi-daemon`
- Try adding manually via IP: Administration → Add Printer → AppSocket/HP JetDirect → enter `socket://<printer-ip>:9100`

**Driver not found:**
- Add `pkgs.gutenprint` or a vendor-specific package (e.g. `pkgs.hplip` for HP) to `environment.systemPackages` in your NixOS config, then rebuild

**CUPS web interface asks for login but rejects credentials:**
- Your user must be in the `lp` or `wheel` group
- Add to configuration.nix: `users.users.aj.extraGroups = [ ... "lp" ];`

---

## Notes
- CUPS web interface: `http://localhost:631/`
- Config file location: `/etc/nixos/hosts/<hostname>/configuration.nix`
- Confirmed working on thinkpad-t14 (aj) as of 2026-04-20
