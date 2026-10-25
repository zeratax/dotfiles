---
name: fritz-wlan
description: Manage the "known WLAN devices" / MAC filter allow-list on all of Jona's FRITZ! access points at once (5690, 7590, Repeater 6000, Repeater 3000) - status vs. the 128-device cap, list/find a device, allow (add) or remove a MAC, name devices, prune junk entries. Use when a Wi-Fi device can't join, a new device needs to be allowed, or the known-device lists need cleaning.
---

# FRITZ! Wi-Fi allow-lists via `fritz-wlan`

The four APs run **without mesh sync** (since 2026-10-24), so each keeps its own
"known WLAN devices" list and, with "Nur bekannte WLAN-Geräte zulassen" on,
enforces it on its own radios. A device has to be on the list of **whichever AP
it connects to**. Each list holds at most **128** devices; at the cap FritzOS
logs that the filter "kann momentan nicht genutzt werden" and devices get
rejected even when they're on it. Background: vault `reference/Network.md`.

Password: `$FRITZ_PASSWORD` (same on every box). If KeePass has a FRITZ!Box
entry, use `agent-kp run --entry … --env FRITZ_PASSWORD --reason … -- fritz-wlan …`;
otherwise it's in the vault's `reference/Network.md`.

```bash
fritz-wlan status                 # per AP: filter on/off, known/128, PC- and junk counts
fritz-wlan list [--ap 7590] [txt] # known devices; flags R = randomized MAC, J = junk
fritz-wlan find <mac|name>        # which APs know it, under which name
fritz-wlan add <mac> [--name N]   # allow on every AP (or --ap X, repeatable)
fritz-wlan remove <mac>           # delete from every AP's list
fritz-wlan rename <mac> <name>    # name it (only the 5690 accepts renames, see below)
fritz-wlan sync-names [--apply]   # PC-xx entries -> the name another AP knows (5690 only)
fritz-wlan prune [--apply]        # delete junk (see below); dry run without --apply
```

APs: `5690` (.1, router), `7590` (.172), `rep6000` (.58), `rep3000` (.44).

**Junk** = name `PC-…`, not connected, no IP, no real name on any AP, and a
randomized MAC (phones' private addresses). `--include-nonrandom` also takes
unnamed vendor MACs. `FRITZ_WLAN_KEEP=<mac>,<mac>` protects specific MACs.

## Safety

- Writes use the web UI's own calls (`data.lua page=wKey`, actions `delete` /
  `add_mac`), renames use TR-064. Before and after every write the tool
  compares the AP's Wi-Fi security settings (encryption, PSK hash, PMF, SSIDs,
  filter) and aborts if anything but the device list changed.
- Renames go through TR-064 `X_AVM-DE_SetHostNameByMACAddress`, which only the
  5690 (DHCP router) accepts: the 7590 answers `820 Internal Error`, the
  repeaters `401 Invalid Action`. Names there are cosmetic; the filter only
  checks MACs.
- Removing a device that's in use, or switching nothing but the list, never
  touches the Wi-Fi password. Don't hand-craft `page=wKey` POSTs with `apply`:
  that resubmits the whole security form.
- The auto-mode classifier blocks agent writes to the routers ("Modify Shared
  Resources"). Read commands (`status`, `list`, `find`, dry runs) are fine;
  for writes, hand Jona the exact `fritz-wlan …` command to run himself.
