---
name: vacuula
description: Check on Jona's Neato robot vacuum through the self-hosted Vacuula server - what it's doing right now, battery, errors, cleaning history and rendered maps of past runs. Use when asked about the vacuum/robot/Neato/"Staubsauger" (is it cleaning, where is it, did it finish, show the map). Read-only unless Jona asks to start/stop it.
---

# Neato robot via `vacuula`

Jona's Neato (a BotVac **D7** Connected, Gen3, serial `GPC50318-4006a0f30ab3`)
talks to a self-hosted Vacuula server, the HA add-on `6a057cb4_vacuula`
(stable, 1.1.0 since 2026-10-25) at **http://192.168.178.181:8089** (web UI at
the same address, or the add-on's "Open Web UI" in HA; override with
`VACUULA_URL`). Background, setup history and gotchas live in the vault:
`projects/vacuula/NOTES.md`.

```bash
vacuula status          # state / action, battery, docked/charging, error, alert
vacuula watch           # print each state change (polls every 10 s); --once for one line
vacuula runs            # cleaning history: start, minutes, m², battery used, problems
vacuula map             # render the latest run to vacuula-<run>.png (or: map <run-id> -o x.png)
vacuula info            # battery health, model/firmware, preferences, schedule (raw JSON)
vacuula robots          # registered robots + connected?
```

Look at the PNG with the Read tool to describe it: dark = walls, white = floor
the lidar saw, blue = cleaned area, red = dock/start.

## What it can and can't tell you

- **No live position.** Gen3 robots don't stream their location; the map is
  uploaded once, **when a run ends**. While it's cleaning you only get state
  (`busy / house cleaning`, `docking`, `suspended cleaning (recharging)` = back
  on the dock mid-run, will resume by itself). "Where is it" = state + latest map.
- A new house clean starts with **exploration**; `maps` stays empty until a run
  comes back `valid_as_persistent_map` (shown in `runs` notes). Zones and no-go
  lines need such a persistent map.
- `getLocalStats` returns `command_not_found` on this firmware; don't bother.
- **After each run it goes offline for ~10 min**: back on the dock it builds and
  uploads the run map, the server times out its connection meanwhile, and it
  reconnects right after the upload (seen 2026-10-21: offline 18:46, map upload
  18:56, connected 18:57). Not a fault; check `runs` afterwards for the new run.
- `status` failing with "not connected" otherwise means the robot isn't talking to the
  server (off, out of Wi-Fi, or the server just restarted; it reconnects within
  about a minute). The robot's Wi-Fi LED is solid when connected.
- **Dropped while docked and idle, never comes back** (vacuula#58/#63): the
  server logs `Robot … disconnected` with no run going, and the robot stays on
  Wi-Fi (it still pings) but doesn't reconnect until it's power-cycled. Seen
  2026-10-25 on server/installer 1.1.0-b3; 1.1.0 is supposed to fix most of it.

## Moving the robot (ask first)

`vacuula cmd <name> [json-params]` sends any robot command, including ones that
make it move (`startCleaning`, `stopCleaning`, `pauseCleaning`,
`resumeCleaning`, `sendToBase`, `findMe` beeps). **Only do this when Jona asks.**
Read-only ones are fine: `getRobotState`, `getGeneralInfo`, `getPreferences`,
`getSchedule`, `getMapBoundaries {"mapId": …}`.

House clean example (category 2 = house, mode 1 eco / 2 normal, navigationMode
1 normal / 2 extra care / 3 deep):

```bash
vacuula cmd startCleaning '{"category": 2, "mode": 1, "navigationMode": 1}'
```

## Raw API (what the CLI wraps)

- `GET /api/robots`, `GET /api/robot/<serial>/runs`, `GET /api/robot/<serial>/maps`
- `GET /api/robot/<serial>/run/<run-id>` (cleaned-path grid) and
  `GET /api/robot/<serial>/maps/<run-id>` (lidar floor grid): 256×256,
  row-major RLE `[[value, count], …]` plus a `legend`
- `POST /api/robot/<serial>/command` with `{"cmd": …, "params": {…}}`; the
  server waits up to 30 s for the robot's answer
- `GET /api/robot/<serial>/connect`: SSE, only emits when the robot pushes an event
- Server logs: `ssh -F /dev/null root@192.168.178.181 'ha apps logs 6a057cb4_vacuula'`
  (full log incl. older lines: `/addon_configs/6a057cb4_vacuula/vacuula.log*`).
  Raw `FloorMap.png`/`RunMap.png` per run are under
  `/addon_configs/6a057cb4_vacuula/uploads/maps/<serial>/<run-id>/`.
