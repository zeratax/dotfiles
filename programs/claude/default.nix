{
  pkgs,
  config,
  lib,
  llm-agents,
  ...
}: let
  # claude-code and its ACP bridge come from llm-agents.nix rather than nixpkgs.
  #
  # Why: nixpkgs tracks these on the normal channel cadence, so `claude-code` there lags a
  # release or two behind — nixos-unstable at 2026-09-04 carried 2.1.258 while llm-agents
  # already had 2.1.261. That gap is not cosmetic: new models only become selectable once
  # the CLI knows their id, which is exactly how Fable 5.1 stayed missing on 2.1.245 even
  # after a full nixpkgs bump (Jona, 2026-09-05). llm-agents.nix updates daily, so the lag
  # is a day at most.
  #
  # Its own nixpkgs is deliberately NOT followed — see the input in flake.nix: the
  # bun2nix-based FODs record hashes against that pin, and overriding it invalidates them.
  agents = llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  home.packages = [
    agents.claude-code
    agents.claude-agent-acp
  ];

  programs.noctalia-shell.plugins.states.claude-code-panel =
    lib.mkIf config.programs.noctalia-shell.enable {
      enabled = true;
      sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
    };
}
