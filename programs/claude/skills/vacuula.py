"""vacuula: read-only CLI for the Vacuula server (self-hosted Neato cloud).

Talks to the server's HTTP API (the same one the web app uses). Read-only by
default; `cmd` sends a raw robot command and is the only thing that can make
the robot move.
"""
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime

BASE = os.environ.get("VACUULA_URL", "http://192.168.178.181:8089").rstrip("/") + "/api"

STATES = {0: "invalid", 1: "idle", 2: "busy", 3: "paused", 4: "error"}
ACTIONS = {
    0: "-", 1: "house cleaning", 2: "spot cleaning", 3: "manual cleaning",
    4: "docking", 5: "user menu active", 6: "suspended cleaning (recharging)",
    7: "updating", 8: "copying logs", 9: "recovering location",
    11: "map cleaning", 12: "exploring map", 13: "acquiring persistent map ids",
    14: "creating/uploading map", 15: "suspended exploration",
}
CATEGORIES = {0: "-", 1: "manual", 2: "house", 3: "spot", 4: "map/zone"}
MODES = {0: "-", 1: "eco", 2: "normal"}
NAV = {1: "normal", 2: "extra care", 3: "deep"}


def api(path, body=None, timeout=40):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method="POST" if data else "GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code} on {path}: {e.read().decode(errors='replace')[:300]}")
    except urllib.error.URLError as e:
        sys.exit(f"cannot reach {BASE}: {e.reason}")
    except OSError as e:  # timeouts/resets mid-response aren't wrapped in URLError
        sys.exit(f"cannot reach {BASE}: {e}")


def pick_serial(serial):
    if serial:
        return serial
    robots = api("/robots") or {}
    if len(robots) != 1:
        sys.exit(f"{len(robots)} robots registered, pass --serial: {', '.join(robots)}")
    return next(iter(robots))


def cmd(serial, name, params=None):
    body = {"cmd": name, **({"params": params} if params else {})}
    return api(f"/robot/{serial}/command", body)


def local(ts):
    if not ts:
        return "-"
    return datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().strftime("%Y-%m-%d %H:%M")


def fmt_state(s):
    d = s.get("details", {})
    c = s.get("cleaning", {})
    avail = [k for k, v in s.get("availableCommands", {}).items() if v]
    lines = [
        f"state:    {STATES.get(s.get('state'), s.get('state'))} / {ACTIONS.get(s.get('action'), s.get('action'))}",
        f"battery:  {d.get('charge')}%{' charging' if d.get('isCharging') else ''}"
        f"{', on dock' if d.get('isDocked') else ', off dock'}",
        f"cleaning: {CATEGORIES.get(c.get('category'), c.get('category'))}, "
        f"{MODES.get(c.get('mode'), c.get('mode'))}, nav {NAV.get(c.get('navigationMode'), c.get('navigationMode'))}",
        f"error:    {s.get('error') or '-'}   alert: {s.get('alert') or '-'}",
        f"schedule: {'on' if d.get('isScheduleEnabled') else 'off'}",
        f"can:      {', '.join(avail) or '-'}",
    ]
    return "\n".join(lines)


def do_robots(a):
    for serial, r in (api("/robots") or {}).items():
        print(f"{serial}  {r['type']}  {'connected' if r['connected'] else 'OFFLINE'}  name={r['name']}")


def do_status(a):
    s = pick_serial(a.serial)
    connected = (api("/robots") or {}).get(s, {}).get("connected")
    if not connected:
        sys.exit(f"{s} is not connected to the server")
    st = cmd(s, "getRobotState")
    if a.json:
        print(json.dumps(st, indent=2))
        return
    print(fmt_state(st))
    meta = st.get("meta", {})
    print(f"robot:    {meta.get('modelName')} fw {meta.get('firmware')} ({s})")


def do_info(a):
    s = pick_serial(a.serial)
    out = {c: cmd(s, c).get("data") for c in ("getGeneralInfo", "getPreferences", "getSchedule")}
    print(json.dumps(out, indent=2))


def do_runs(a):
    s = pick_serial(a.serial)
    runs = sorted((r["run"] for r in api(f"/robot/{s}/runs") or []), key=lambda r: r["start_at"])
    if a.json:
        print(json.dumps(runs, indent=2))
        return
    print(f"{'id':22} {'start':16} {'min':>4} {'m²':>6} {'batt':>9} {'status':10} {'type':6} notes")
    for r in runs[-a.last:]:
        dur = "-"
        if r.get("end_at"):
            t0 = datetime.fromisoformat(r["start_at"].replace("Z", "+00:00"))
            t1 = datetime.fromisoformat(r["end_at"].replace("Z", "+00:00"))
            dur = str(round((t1 - t0).total_seconds() / 60))
        notes = []
        if r.get("error"):
            notes.append(f"error={r['error']}")
        if r.get("time_in_error"):
            notes.append(f"{r['time_in_error']}s in error")
        if r.get("picked_up_count"):
            notes.append(f"picked up {r['picked_up_count']}x")
        if r.get("suspended_cleaning_charging_count"):
            notes.append(f"recharged {r['suspended_cleaning_charging_count']}x")
        if r.get("localization_lost"):
            notes.append("lost localization")
        if r.get("valid_as_persistent_map"):
            notes.append("valid persistent map")
        batt = f"{r.get('run_charge_at_start')}→{r.get('run_charge_at_end')}%"
        print(f"{r['id']:22} {local(r['start_at']):16} {dur:>4} {r.get('cleaned_area') or 0:6.1f} "
              f"{batt:>9} {r.get('status', '-'):10} {CATEGORIES.get(r.get('category'), '?'):6} {', '.join(notes)}")


def rle_decode(m):
    cells = []
    for value, count in m["rle"]:
        cells.extend([value] * count)
    return cells, m["width"], m["height"]


def do_map(a):
    from PIL import Image

    s = pick_serial(a.serial)
    run_id = a.run
    if run_id in (None, "latest"):
        runs = api(f"/robot/{s}/runs") or []
        if not runs:
            sys.exit("no runs uploaded yet (the robot uploads its map when a run ends)")
        run_id = max(runs, key=lambda r: r["run"]["start_at"])["id"]
    run = api(f"/robot/{s}/run/{run_id}", timeout=60)
    try:
        # the lidar floor map of the same run; missing for some runs
        with urllib.request.urlopen(f"{BASE}/robot/{s}/maps/{run_id}", timeout=60) as r:
            floor = json.loads(r.read())
    except urllib.error.HTTPError:
        floor = None

    fcells, w, h = rle_decode(floor) if floor and "rle" in floor else (None, run["width"], run["height"])
    rcells, rw, rh = rle_decode(run)
    img = Image.new("RGB", (w, h), (235, 235, 235))
    px = img.load()
    if fcells:
        for i, v in enumerate(fcells):
            if v == 1:
                px[i % w, i // w] = (255, 255, 255)
            elif v == 2:
                px[i % w, i // w] = (40, 40, 40)
    if (rw, rh) == (w, h):
        legend = run.get("legend", {})
        for i, v in enumerate(rcells):
            label = legend.get(str(v), "")
            if label.startswith("path"):
                x, y = i % w, i // w
                if fcells is None or fcells[i] != 2:
                    px[x, y] = (110, 170, 255)
            elif label.startswith("dock"):
                px[i % w, i // w] = (230, 60, 40)
    # crop to content
    bbox = Image.eval(img.convert("L"), lambda v: 0 if v == 235 else 255).getbbox()
    if bbox:
        pad = 6
        bbox = (max(bbox[0] - pad, 0), max(bbox[1] - pad, 0), min(bbox[2] + pad, w), min(bbox[3] + pad, h))
        img = img.crop(bbox)
    img = img.resize((img.width * a.scale, img.height * a.scale), Image.NEAREST)
    out = a.output or f"vacuula-{run_id.replace(':', '')}.png"
    img.save(out)
    print(f"{out}  (run {run_id}: dark = walls, white = seen floor, blue = cleaned, red = dock/start)")


def do_watch(a):
    s = pick_serial(a.serial)
    last = None
    while True:
        try:
            robots = api("/robots") or {}
            if not robots.get(s, {}).get("connected"):
                line = key = "OFFLINE (not connected to server)"
            else:
                st = cmd(s, "getRobotState")
                d = st.get("details", {})
                flags = (f"{' charging' if d.get('isCharging') else ''}"
                         f"{', docked' if d.get('isDocked') else ''}"
                         f"{', ERROR ' + str(st.get('error')) if st.get('error') else ''}"
                         f"{', alert ' + str(st.get('alert')) if st.get('alert') else ''}")
                line = f"{STATES.get(st.get('state'))} / {ACTIONS.get(st.get('action'))}, {d.get('charge')}%{flags}"
                # battery only counts as a change in 10% steps, or every poll is an event
                key = (st.get("state"), st.get("action"), flags, (d.get("charge") or 0) // 10)
        except SystemExit as e:
            # robot dropped mid-request (e.g. while uploading its map) or server restarting
            line = key = f"UNREACHABLE ({e})"
        if key != last:
            print(f"{datetime.now().strftime('%H:%M:%S')}  {line}", flush=True)
            last = key
        if a.once:
            return
        time.sleep(a.interval)


def do_cmd(a):
    s = pick_serial(a.serial)
    params = json.loads(a.params) if a.params else None
    print(json.dumps(cmd(s, a.name, params), indent=2))


def main():
    p = argparse.ArgumentParser(prog="vacuula", description=__doc__.splitlines()[0])
    p.add_argument("--serial", help="robot serial (default: the only registered robot)")
    sub = p.add_subparsers(dest="sub", required=True)
    sub.add_parser("robots", help="list robots and connection status").set_defaults(f=do_robots)
    sp = sub.add_parser("status", help="what the robot is doing right now")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(f=do_status)
    sub.add_parser("info", help="battery/model, preferences, schedule").set_defaults(f=do_info)
    sp = sub.add_parser("runs", help="cleaning history")
    sp.add_argument("--last", type=int, default=20)
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(f=do_runs)
    sp = sub.add_parser("map", help="render a run's map to PNG")
    sp.add_argument("run", nargs="?", default="latest", help="run id or 'latest'")
    sp.add_argument("-o", "--output")
    sp.add_argument("--scale", type=int, default=4)
    sp.set_defaults(f=do_map)
    sp = sub.add_parser("watch", help="print state changes (polls getRobotState)")
    sp.add_argument("--interval", type=int, default=10)
    sp.add_argument("--once", action="store_true")
    sp.set_defaults(f=do_watch)
    sp = sub.add_parser("cmd", help="send a raw robot command (CAN MOVE THE ROBOT)")
    sp.add_argument("name")
    sp.add_argument("params", nargs="?", help="JSON params object")
    sp.set_defaults(f=do_cmd)
    a = p.parse_args()
    a.f(a)


if __name__ == "__main__":
    main()
