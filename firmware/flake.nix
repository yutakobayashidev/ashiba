{
  description = "Arduino and PlatformIO firmware development";
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
                skills.firmware-workflow = {
                  from = "local";
                  path = "firmware-workflow";
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

          arduinoIDE = if darwin then casks.arduino-ide else pkgs.arduino-ide;
          firmwarePackages = [
            pkgs.arduino-cli
            (if darwin then pkgs.platformio-core else pkgs.platformio)
          ];
          shellHook = ''
            export ARDUINO_DIRECTORIES_DATA="$PWD/.firmware/arduino/data"
            export ARDUINO_DIRECTORIES_DOWNLOADS="$PWD/.firmware/arduino/downloads"
            export ARDUINO_DIRECTORIES_USER="$PWD/firmware/arduino"
            export PLATFORMIO_CORE_DIR="$PWD/.firmware/platformio"
            mkdir -p "$ARDUINO_DIRECTORIES_DATA" "$ARDUINO_DIRECTORIES_DOWNLOADS" "$PLATFORMIO_CORE_DIR"
            ${skills.shellHook}
          '';

        in
        {
          _module.args.pkgs = pkgs;
          devShells = {
            default = pkgs.mkShellNoCC {
              packages = [ pkgs.git ] ++ firmwarePackages;
              inherit shellHook;
            };
            ide = pkgs.mkShellNoCC {
              packages = [
                pkgs.git
                arduinoIDE
              ]
              ++ firmwarePackages
              ++ pkgs.lib.optional darwin (launchApp "firmware-arduino-ide" arduinoIDE "Arduino IDE.app");
              inherit shellHook;
            };
          };
          formatter = pkgs.nixfmt;
          packages.skills = skills.bundle;
          checks.skills = pkgs.runCommand "firmware-skills-check" { } ''
            mkdir project
            cd project
            ${skills.shellHook}
            for target in .agents .codex .claude .opencode; do
              test -f "$target/skills/firmware-workflow/SKILL.md"
              test -f "$target/skills/.agent-skills-managed.json"
            done
            touch "$out"
          '';
        };
    };
}
