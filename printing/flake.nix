{
  description = "3D print preparation with PrusaSlicer";
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
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        brew-api.follows = "brew-api";
        nix-darwin.follows = "nix-darwin";
      };
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
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
                skills.printing-workflow = {
                  from = "local";
                  path = "printing-workflow";
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

          darwin = pkgs.stdenv.hostPlatform.isDarwin;
          casks = if darwin then inputs.brew-nix.packages.${system} else { };
          launchApp =
            name: package: app:
            pkgs.writeShellScriptBin name ''
              exec /usr/bin/open -a ${pkgs.lib.escapeShellArg "${package}/Applications/${app}"} --args "$@"
            '';

        in
        {
          _module.args.pkgs = pkgs;
          devShells = {
            default = pkgs.mkShellNoCC {
              packages =
                if darwin then
                  [
                    pkgs.git
                    casks.prusaslicer
                    (launchApp "printing-prusa-slicer" casks.prusaslicer "Original Prusa Drivers/PrusaSlicer.app")
                  ]
                else
                  [
                    pkgs.git
                    pkgs.prusa-slicer
                  ];
              shellHook = skills.shellHook;
            };
          };
          formatter = pkgs.nixfmt;
          packages.skills = skills.bundle;
          checks.skills = pkgs.runCommand "printing-skills-check" { } ''
            mkdir project
            cd project
            ${skills.shellHook}
            for target in .agents .codex .claude .opencode; do
              test -f "$target/skills/printing-workflow/SKILL.md"
              test -f "$target/skills/.agent-skills-managed.json"
            done
            touch "$out"
          '';
        };
    };
}
