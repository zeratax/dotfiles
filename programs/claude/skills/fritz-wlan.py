"""fritz-wlan: manage the "known WLAN devices" (MAC filter allow-list) on every FRITZ! AP.

The APs run without mesh sync, so each one keeps its own list and enforces its
own MAC filter. The filter holds at most 128 devices; past that FritzOS logs
that it "kann momentan nicht genutzt werden".

Writes go through the same data.lua calls the web UI makes (page=wKey,
actions `add_mac` / `delete`); renames through TR-064
(Hosts:1 X_AVM-DE_SetHostNameByMACAddress). Every write snapshots the AP's
Wi-Fi security settings before and after and stops if anything but the device
list changed.

Password: $FRITZ_PASSWORD (all boxes share it).
"""

import argparse
import getpass
import hashlib
import json
import os
import re
import sys
import urllib.parse
import urllib.request

from fritzconnection import FritzConnection
from fritzconnection.core.exceptions import FritzConnectionException

# name -> (address, username); the repeaters log in with an empty username
APS = {
    "5690": ("192.168.178.1", "fritz9379"),
    "7590": ("192.168.178.172", "fritz5367"),
    "rep6000": ("192.168.178.58", "fritz9379"),
    "rep3000": ("192.168.178.44", ""),
}
FILTER_CAP = 128
MAC_RE = re.compile(r"^([0-9a-f]{2}[:-]?){5}[0-9a-f]{2}$", re.I)
UUID_RE = re.compile(r"^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", re.I)
# settings that must never change as a side effect of a list edit
GUARDED = ["wpaType", "pmfMode", "isEncInterop", "isolation", "activeMACFilter",
           "stickAndSurf", "ssid", "ssidScnd", "ssidThrd", "ssidFrth",
           "apEnabled", "apScndEnabled", "apThrdEnabled", "apFrthEnabled"]


def password():
    if not os.environ.get("FRITZ_PASSWORD"):
        if not sys.stdin.isatty():
            sys.exit("fritz-wlan: set $FRITZ_PASSWORD (e.g. via agent-kp run --env FRITZ_PASSWORD)")
        os.environ["FRITZ_PASSWORD"] = getpass.getpass("FRITZ!Box password: ")
    return os.environ["FRITZ_PASSWORD"]


def norm_mac(mac):
    hexes = re.sub(r"[^0-9a-f]", "", mac.lower())
    if len(hexes) != 12:
        sys.exit(f"fritz-wlan: not a MAC address: {mac}")
    return ":".join(hexes[i:i + 2] for i in range(0, 12, 2)).upper()


def randomized(mac):
    return int(mac[:2], 16) & 2 == 2


def on(value):
    # data.lua returns flags as "0"/"1" strings
    return str(value).lower() in ("1", "true")


class Box:
    def __init__(self, name):
        self.name = name
        self.host, self.user = APS[name]
        self.sid = None
        self._tr064 = None
        self._last_guard = None  # after-snapshot of the previous write = next before

    # -- data.lua session ---------------------------------------------------
    def _post(self, path, data):
        req = urllib.request.Request(f"http://{self.host}{path}",
                                     data=urllib.parse.urlencode(data).encode())
        return urllib.request.urlopen(req, timeout=20).read().decode()

    def __enter__(self):
        url = f"http://{self.host}/login_sid.lua?version=2"
        xml = urllib.request.urlopen(url, timeout=10).read().decode()
        challenge = re.search(r"<Challenge>(.*?)</Challenge>", xml).group(1)
        _, it1, salt1, it2, salt2 = challenge.split("$")
        h1 = hashlib.pbkdf2_hmac("sha256", password().encode(), bytes.fromhex(salt1), int(it1))
        resp = salt2 + "$" + hashlib.pbkdf2_hmac("sha256", h1, bytes.fromhex(salt2), int(it2)).hex()
        xml = self._post("/login_sid.lua?version=2", {"username": self.user, "response": resp})
        self.sid = re.search(r"<SID>(.*?)</SID>", xml).group(1)
        if set(self.sid) == {"0"}:
            block = re.search(r"<BlockTime>(\d+)</BlockTime>", xml)
            wait = f"; the box now blocks logins for {block.group(1)} s" if block and block.group(1) != "0" else ""
            sys.exit(f"fritz-wlan: login to {self.name} ({self.host}) as user '{self.user}' failed{wait}. "
                     "It needs that account's password (vault reference/Network.md), not a personal login; "
                     "unset FRITZ_PASSWORD to be prompted for it.")
        return self

    def __exit__(self, *exc):
        if self.sid:
            self._post("/login_sid.lua?version=2", {"logout": 1, "sid": self.sid})

    def wlan(self):
        raw = self._post("/data.lua", {"xhr": 1, "page": "wKey", "lang": "de", "sid": self.sid})
        return json.loads(raw)["data"]["wlan"]

    def devices(self):
        return self.wlan().get("knownWlanDevices", [])

    def _guard(self, wlan):
        snap = {k: wlan.get(k) for k in GUARDED}
        snap["psk"] = hashlib.sha256(str(wlan.get("psk")).encode()).hexdigest()
        return snap

    def _submit(self, action, params):
        """Run a wKey action the way newval.submit does, confirming if asked."""
        before = self._last_guard or self._guard(self.wlan())
        data = {"xhr": 1, "page": "wKey", "lang": "de", "sid": self.sid, action: "", **params}
        answer = json.loads(self._post("/data.lua", data)).get("data", {})
        if answer.get(action) == "confirm":
            data["confirmed"] = ""
            answer = json.loads(self._post("/data.lua", data)).get("data", {})
        after_wlan = self.wlan()
        after = self._guard(after_wlan)
        if before != after:
            changed = [k for k in before if before[k] != after[k]]
            sys.exit(f"fritz-wlan: ABORT, {self.name}: {action} changed Wi-Fi settings {changed}; check the box by hand")
        self._last_guard = after
        if answer.get(action) not in (None, "", "ok", "done"):
            print(f"  {self.name}: {action} answered {json.dumps(answer)[:300]}", file=sys.stderr)
        return after_wlan.get("knownWlanDevices", [])

    def delete(self, uid):
        return self._submit("delete", {"device": uid})

    def add(self, mac):
        parts = mac.lower().split(":")
        return self._submit("add_mac", {f"mac{i}": p for i, p in enumerate(parts)})

    # -- TR-064 ---------------------------------------------------------------
    def rename(self, mac, name):
        if self._tr064 is None:
            self._tr064 = FritzConnection(address=self.host, user=self.user,
                                          password=password(), timeout=15)
        try:
            self._tr064.call_action("Hosts1", "X_AVM-DE_SetHostNameByMACAddress",
                                    NewMACAddress=mac, NewHostName=name)
        except FritzConnectionException as e:
            # the 7590 (IP client) answers 820 Internal Error: it doesn't own the names
            return str(e).replace("\n", " ").strip()
        return None


def pick_aps(names):
    if not names:
        return list(APS)
    bad = [n for n in names if n not in APS]
    if bad:
        sys.exit(f"fritz-wlan: unknown AP {bad}; known: {', '.join(APS)}")
    return names


def snapshot(aps):
    out = {}
    for ap in aps:
        with Box(ap) as box:
            out[ap] = box.wlan()
    return out


def real_names(snap):
    """MAC -> real (non-PC-, non-UUID) names seen on any AP, the 5690's first."""
    names = {}
    for ap in ["5690"] + [a for a in snap if a != "5690"]:
        for e in snap.get(ap, {}).get("knownWlanDevices", []):
            n = e["name"]
            if n.startswith("PC-") or UUID_RE.match(n):
                continue
            lst = names.setdefault(e["mac"].upper(), [])
            if n not in lst:
                lst.append(n)
    return names


def junk(snap, ap, include_nonrandom=False):
    named = real_names(snap)
    keep = {norm_mac(m) for m in os.environ.get("FRITZ_WLAN_KEEP", "").split(",") if m.strip()}
    out = []
    for e in snap[ap].get("knownWlanDevices", []):
        mac = e["mac"].upper()
        if not e["name"].startswith("PC-") or e["type"] != "passive" or e["ip"] not in ("-", ""):
            continue
        if mac in named or mac in keep:
            continue
        if not include_nonrandom and not randomized(mac):
            continue
        out.append(e)
    return out


# -- commands -----------------------------------------------------------------
def cmd_status(args):
    snap = snapshot(list(APS))  # junk detection needs every AP's names
    for ap in pick_aps(args.ap):
        w = snap[ap]
        n = len(w.get("knownWlanDevices", []))
        pc = sum(e["name"].startswith("PC-") for e in w.get("knownWlanDevices", []))
        warn = "  <-- AT/OVER THE FILTER CAP" if n >= FILTER_CAP and on(w.get("activeMACFilter")) else ""
        print(f"{ap:8} {APS[ap][0]:16} filter={'on ' if on(w.get('activeMACFilter')) else 'off'} "
              f"known={n:3}/{FILTER_CAP} PC-={pc:3} junk={len(junk(snap, ap)):3} wpa={w.get('wpaType')}{warn}")


def cmd_list(args):
    snap = snapshot(pick_aps(args.ap))
    named = real_names(snap)
    pat = args.match.lower() if args.match else None
    for ap, w in snap.items():
        junk_uids = {e["uid"] for e in junk(snap, ap, include_nonrandom=True)}
        for e in sorted(w.get("knownWlanDevices", []), key=lambda e: e["name"].lower()):
            line = f"{ap:8} {e['mac']} {e['type']:7} {e['ip']:16} {e['name']}"
            if e["name"].startswith("PC-") and e["mac"].upper() in named:
                line += f"  (= {named[e['mac'].upper()][0]})"
            flags = ("R" if randomized(e["mac"]) else "-") + ("J" if e["uid"] in junk_uids else "-")
            line = f"{flags} {line}"
            if pat and pat not in line.lower():
                continue
            print(line)


def cmd_find(args):
    q = args.query
    mac = norm_mac(q) if MAC_RE.match(q.strip()) else None
    for ap, w in snapshot(list(APS)).items():
        for e in w.get("knownWlanDevices", []):
            if (mac and e["mac"].upper() == mac) or (not mac and q.lower() in e["name"].lower()):
                print(f"{ap:8} {e['mac']} {e['type']:7} {e['ip']:16} {e['name']} ({e['uid']})")


def cmd_add(args):
    mac = norm_mac(args.mac)
    for ap in pick_aps(args.ap):
        with Box(ap) as box:
            devs = box.devices()
            if any(e["mac"].upper() == mac for e in devs):
                print(f"{ap:8} already known")
            elif len(devs) >= FILTER_CAP:
                print(f"{ap:8} SKIP: list is full ({len(devs)}/{FILTER_CAP}); run `fritz-wlan prune` first")
                continue
            else:
                devs = box.add(mac)
                ok = any(e["mac"].upper() == mac for e in devs)
                print(f"{ap:8} {'added' if ok else 'NOT added (check the box)'} ({len(devs)} known)")
            if args.name:
                err = box.rename(mac, args.name)
                print(f"{ap:8} {'rename FAILED: ' + err if err else 'named ' + args.name}")


def cmd_remove(args):
    mac = norm_mac(args.mac)
    for ap in pick_aps(args.ap):
        with Box(ap) as box:
            hit = [e for e in box.devices() if e["mac"].upper() == mac]
            if not hit:
                print(f"{ap:8} not known")
                continue
            devs = box.delete(hit[0]["uid"])
            gone = not any(e["mac"].upper() == mac for e in devs)
            print(f"{ap:8} {'removed' if gone else 'NOT removed (check the box)'} ({len(devs)} known)")


def cmd_rename(args):
    mac = norm_mac(args.mac)
    for ap in pick_aps(args.ap):
        with Box(ap) as box:
            if not any(e["mac"].upper() == mac for e in box.devices()):
                print(f"{ap:8} not known, skipped")
                continue
            err = box.rename(mac, args.name)
            print(f"{ap:8} {'rename FAILED: ' + err if err else 'named ' + args.name}")


def cmd_sync_names(args):
    snap = snapshot(list(APS))
    named = real_names(snap)
    for ap in pick_aps(args.ap):
        todo = [(e["mac"].upper(), named[e["mac"].upper()][0]) for e in snap[ap].get("knownWlanDevices", [])
                if e["name"].startswith("PC-") and e["mac"].upper() in named]
        for mac, name in todo:
            print(f"{ap:8} {mac} -> {name}")
        if args.apply and todo:
            done = 0
            with Box(ap) as box:
                for mac, name in todo:
                    err = box.rename(mac, name)
                    if err:
                        print(f"{ap:8} rename FAILED ({err}); skipping this AP")
                        break
                    done += 1
            print(f"{ap:8} renamed {done}/{len(todo)}")
    if not args.apply:
        print("(dry run; add --apply to rename)")


def cmd_prune(args):
    snap = snapshot(list(APS))  # names on the other APs decide what's junk
    for ap in pick_aps(args.ap):
        victims = junk(snap, ap, include_nonrandom=args.include_nonrandom)
        before = len(snap[ap].get("knownWlanDevices", []))
        print(f"{ap:8} {before} known, {len(victims)} junk -> {before - len(victims)}")
        for e in victims:
            print(f"         {e['mac']} {e['name']} ({e['uid']})")
        if args.apply and victims:
            with Box(ap) as box:
                for i, e in enumerate(victims, 1):
                    devs = box.delete(e["uid"])
                    print(f"{ap:8} deleted {i}/{len(victims)} {e['mac']} ({len(devs)} known)", flush=True)
                print(f"{ap:8} now {len(devs)} known")
    if not args.apply:
        print("(dry run; add --apply to delete)")


def main():
    p = argparse.ArgumentParser(prog="fritz-wlan", description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)

    def add(name, fn, help_):
        sp = sub.add_parser(name, help=help_)
        sp.set_defaults(fn=fn)
        sp.add_argument("--ap", action="append", help=f"limit to an AP ({', '.join(APS)}); repeatable")
        return sp

    add("status", cmd_status, "per AP: filter on/off, known devices vs. the 128 cap, junk count")
    sp = add("list", cmd_list, "known devices (flags: R = randomized MAC, J = junk candidate)")
    sp.add_argument("match", nargs="?", help="only lines containing this text")
    sp = sub.add_parser("find", help="which APs know a MAC or name")
    sp.set_defaults(fn=cmd_find)
    sp.add_argument("query")
    sp = add("add", cmd_add, "allow a MAC on every AP (or --ap ...)")
    sp.add_argument("mac")
    sp.add_argument("--name", help="also set its name")
    sp = add("remove", cmd_remove, "delete a MAC from every AP's list (or --ap ...)")
    sp.add_argument("mac")
    sp = add("rename", cmd_rename, "set a device's name on every AP that knows it")
    sp.add_argument("mac")
    sp.add_argument("name")
    sp = add("sync-names", cmd_sync_names, "rename PC-xx entries to the name another AP knows (dry run)")
    sp.add_argument("--apply", action="store_true")
    sp = add("prune", cmd_prune,
             "delete junk: PC- name, passive, no IP, not named on any AP, randomized MAC (dry run)")
    sp.add_argument("--apply", action="store_true")
    sp.add_argument("--include-nonrandom", action="store_true",
                    help="also delete unnamed entries with a vendor (non-randomized) MAC")
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
