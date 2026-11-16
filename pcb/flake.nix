{
  description = "PCB design and validation with KiCad";
  inputs = {
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem =
        { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          agentLib = inputs.agent-skills.lib.agent-skills;
          skills =
            let
              sources.local.path = ./skills;
              selection = agentLib.selectSkills {
                inherit sources;
                catalog = agentLib.discoverCatalog sources;
                skills.pcb-workflow = {
                  from = "local";
                  path = "pcb-workflow";
                  rewriteCommands = false;
                };
              };
              bundle = agentLib.mkBundle { inherit pkgs selection; };
              targets = pkgs.lib.genAttrs [ "agents" "codex" "claude" "opencode" ] (
                name: agentLib.defaultLocalTargets.${name} // { enable = true; }
              );
              # Project copies belong to the current user, not the Nix Store's UID/GID.
              syncPkgs = pkgs // {
                rsync = pkgs.writeShellScriptBin "rsync" ''
                  args=()
                  for arg in "$@"; do
                    if [[ "$arg" == -- ]]; then
                      args+=(--no-owner --no-group)
                    fi
                    args+=("$arg")
                  done
                  exec ${pkgs.rsync}/bin/rsync "''${args[@]}"
                '';
              };
            in
            {
              inherit bundle;
              shellHook = agentLib.mkShellHook {
                pkgs = syncPkgs;
                inherit bundle targets;
              };
            };

        in
        {
          _module.args.pkgs = pkgs;
          devShells = {
            default = pkgs.mkShellNoCC {
              packages = [
                pkgs.git
                (pkgs.kicad.override { stable = true; })
              ];
              shellHook = skills.shellHook;
            };
          };
          formatter = pkgs.nixfmt;
          packages.skills = skills.bundle;
          checks.skills = pkgs.runCommand "pcb-skills-check" { } ''
            mkdir project
            cd project
            ${skills.shellHook}
            for target in .agents .codex .claude .opencode; do
              test -f "$target/skills/pcb-workflow/SKILL.md"
              test -f "$target/skills/.agent-skills-managed.json"
            done
            touch "$out"
          '';
        };
    };
}
