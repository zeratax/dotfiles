# dotfiles

Personal dotfiles managed with [Home Manager](https://github.com/nix-community/home-manager) flakes.

## Hosts

Machine configs are defined in `flake.nix` as `homeConfigurations`:

| Configuration | Machine | Profile |
| --- | --- | --- |
| `jonaa@surface` | NixOS laptop | `desktop` + KeePassXC 2.8 beta |
| `jonaa@kaine` | CachyOS, NVIDIA via nixGL | `gaming` |
| `jabdinghoff@LT-JABDINGHOFF` | WSL work machine (x86_64) | `wsl` |
| `jabdinghoff@sf-jabdinghoff` | WSL work machine (aarch64) | `wsl` |
| `minimal` | any machine, as `$USER` | `minimal` |

## Profiles

- `minimal` — shell, git/jj, editors and CLI tools; the base of every profile
- `minimalDesktop` — `minimal` + GUI basics (ghostty, mpv, zed, KeePassXC, …)
- `desktop` — `minimalDesktop` + the niri/noctalia desktop, Firefox, Vesktop, …
- `gaming` — `minimalDesktop` + MangoHud and protontricks
- `wsl` — `minimal` + VS Code server

## Setup

```sh
git clone git@github.com:ZerataX/dotfiles.git ~/Projects/dotfiles
```

Apply with:

```sh
nh home switch
```

On kaine use `nhs` instead: it adds `--impure` so nixGL can detect the running NVIDIA driver, and a login service runs it again when the loaded driver changes.

Per-machine settings (git user, ssh key, gpg) are passed via `userConfig`, per-host hardware knobs (e.g. `lowEndGpu`) via `hostConfig`.

## Neovim

Neovim config lives in a [separate repo](https://github.com/zeratax/neovim-config) with its own flake. It ships a fully wrapped neovim binary with all LSPs, formatters, and tools on PATH. The dotfiles consume it as a flake input.

For local neovim config development, the `nhl` alias switches with a local checkout as the input:

```sh
nh home switch -- --override-input neovim-config path:$HOME/Projects/neovim-config
```

(On kaine `nhl` uses `~/git/neovim-config`.)

## Structure

```
flake.nix       machine definitions and flake inputs
profiles/       machine profiles (see above)
programs/       per-program home-manager modules
services/       user services (niri session restore, sshfs mount, plasmashell fix)
patches/        patches applied to flake inputs at eval time
```
