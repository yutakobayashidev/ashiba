{
  description = "Composable DIY environments for firmware, CAD, PCB design and 3D printing";
  inputs = {
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
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
          stable = import inputs.nixpkgs-stable {
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
                skills.diy-workflow = {
                  from = "local";
                  path = "diy-workflow";
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
          casks = if pkgs.stdenv.hostPlatform.isDarwin then inputs.brew-nix.packages.${system} else { };
          mkShell =
            {
              features,
              extraPackages ? [ ],
            }:
            let
              inherit (pkgs) lib;
              darwin = pkgs.stdenv.hostPlatform.isDarwin;
              # Nixpkgs' Linux wrappers provide an FHS environment for downloaded toolchains.
              firmware = [
                pkgs.arduino-cli
                (if darwin then pkgs.platformio-core else pkgs.platformio)
              ];
              arduinoIDE = if darwin then casks.arduino-ide else pkgs.arduino-ide;
              freecad = if darwin then casks.freecad else stable.freecad;
              # Cask applications are not linked into /Applications by a dev shell.
              launchApp =
                name: package: app:
                pkgs.writeShellScriptBin name ''
                  exec /usr/bin/open -a ${lib.escapeShellArg "${package}/Applications/${app}"} --args "$@"
                '';
              groups = {
                inherit firmware;
                arduino-ide = [
                  arduinoIDE
                ]
                ++ lib.optional darwin (launchApp "diy-arduino-ide" arduinoIDE "Arduino IDE.app");
                cad = [
                  freecad
                  pkgs.openscad
                ]
                ++ lib.optional darwin (launchApp "diy-freecad" freecad "FreeCAD.app");
                pcb = [ (pkgs.kicad.override { stable = true; }) ];
                printing =
                  if darwin then
                    [
                      casks.prusaslicer
                      (launchApp "diy-prusa-slicer" casks.prusaslicer "Original Prusa Drivers/PrusaSlicer.app")
                    ]
                  else
                    [ pkgs.prusa-slicer ];
              };
              unknown = lib.subtractLists (builtins.attrNames groups) features;
            in
            assert lib.assertMsg (unknown == [ ]) "Unknown DIY features: ${lib.concatStringsSep ", " unknown}";
            pkgs.mkShellNoCC {
              packages = [
                pkgs.git
              ]
              ++ lib.unique (lib.concatMap (name: groups.${name}) features)
              ++ extraPackages;
              shellHook = ''
                export DIY_WORKSPACE="$PWD"
                export ARDUINO_DIRECTORIES_DATA="$DIY_WORKSPACE/.diy/arduino/data"
                export ARDUINO_DIRECTORIES_DOWNLOADS="$DIY_WORKSPACE/.diy/arduino/downloads"
                export ARDUINO_DIRECTORIES_USER="$DIY_WORKSPACE/firmware/arduino"
                export PLATFORMIO_CORE_DIR="$DIY_WORKSPACE/.diy/platformio"
                mkdir -p "$ARDUINO_DIRECTORIES_DATA" "$ARDUINO_DIRECTORIES_DOWNLOADS" "$PLATFORMIO_CORE_DIR"
                ${skills.shellHook}
              '';
            };
        in
        {
          _module.args.pkgs = pkgs;
          devShells = builtins.mapAttrs (_: features: mkShell { inherit features; }) (
            {
              default = [ "firmware" ];
              electronics = [
                "firmware"
                "arduino-ide"
              ];
              cad = [ "cad" ];
              printing = [ "printing" ];
              # Example: enclosure = [ "firmware" "cad" ];
            }
            // pkgs.lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
              # The pinned Nixpkgs KiCad package is marked broken on Darwin.
              pcb = [ "pcb" ];
              full = [
                "firmware"
                "arduino-ide"
                "cad"
                "pcb"
                "printing"
              ];
            }
          );
          formatter = pkgs.nixfmt;
          packages.skills = skills.bundle;
          checks = {
            skills = pkgs.runCommand "diy-skills-check" { } ''
              mkdir project
              cd project
              ${skills.shellHook}
              for target in .agents .codex .claude .opencode; do
                test -f "$target/skills/diy-workflow/SKILL.md"
                test -f "$target/skills/.agent-skills-managed.json"
              done
              touch "$out"
            '';
          };
        };
    };
}
