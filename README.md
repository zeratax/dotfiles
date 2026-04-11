# dotfiles

Personal dotfiles managed with [Home Manager](https://github.com/nix-community/home-manager) flakes.

## Profiles

- `wsl` — WSL work machines
- `full` — personal desktop with full GUI stack
- `minimal` — base config for any machine

## Setup

```sh
git clone git@github.com:ZerataX/dotfiles.git ~/git/dotfiles
```

Machine configs are defined in `flake.nix` as `homeConfigurations`. Apply with:

```sh
nh home switch
```

Per-machine settings (git user, ssh key, gpg) are passed via `userConfig`.

## Neovim

Neovim config lives in a [separate repo](https://github.com/zeratax/neovim-config) with its own flake. It ships a fully wrapped neovim binary with all LSPs, formatters, and tools on PATH. The dotfiles consume it as a flake input.

For local neovim config development:

```sh
nh home switch --override-input neovim-config path:$HOME/git/neovim-config
```

## Structure

```
profiles/       machine profiles (wsl, full, minimal)
programs/       per-program home-manager modules
flake.nix       machine definitions and flake inputs
```
