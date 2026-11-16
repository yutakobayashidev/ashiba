{
  description = "Android development and APK analysis for Linux coding agents";

  inputs.flake-parts = {
    url = "github:hercules-ci/flake-parts";
    inputs.nixpkgs-lib.follows = "nixpkgs";
  };
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.agent-skills = {
    url = "github:Kyure-A/agent-skills-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      nixpkgs,
      agent-skills,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem =
        { system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };
          settings = {
            # Match compileSdk/buildToolsVersion in the application's Gradle configuration.
            platformVersion = "36";
            buildToolsVersion = "36.0.0";
            # Set false for build-only CI or physical devices (avoids system-image downloads).
            emulator = true;
          };
          agentLib = agent-skills.lib.agent-skills;
          skills =
            let
              sources = agentLib.sourcesFromLock {
                manifestsDir = ./registry/sources;
                lockFile = ./registry/sources.lock.json;
              };
              catalog = agentLib.discoverCatalog sources;
              names = map (skill: builtins.baseNameOf skill.relPath) (builtins.attrValues catalog);
              # Flat directories work for agents that do not recursively discover skills.
              explicit = pkgs.lib.mapAttrs' (
                _: skill:
                pkgs.lib.nameValuePair (builtins.baseNameOf skill.relPath) {
                  from = "android";
                  path = skill.relPath;
                  rewriteCommands = false;
                }
              ) catalog;
              selection =
                assert builtins.length names == builtins.length (pkgs.lib.unique names);
                agentLib.selectSkills {
                  inherit catalog sources;
                  skills = explicit;
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
          mkMobileShell =
            {
              analysis ? false,
              nativeAnalysis ? false,
              extraPackages ? [ ],
            }:
            let
              inherit (pkgs) lib;
              imageType = if analysis then "default" else "google_apis";
              composition = pkgs.androidenv.composeAndroidPackages {
                platformVersions = [ settings.platformVersion ];
                buildToolsVersions = [ settings.buildToolsVersion ];
                toolsVersion = null;
                includeCmake = false;
                includeNDK = false;
                includeEmulator = settings.emulator;
                includeSystemImages = settings.emulator;
                systemImageTypes = [ imageType ];
                abiVersions = [ "x86_64" ];
              };
              sdk = "${composition.androidsdk}/libexec/android-sdk";
              mobile = pkgs.writeShellApplication {
                name = "mobile";
                runtimeInputs = [
                  pkgs.coreutils
                  pkgs.android-cli
                ];
                text = builtins.readFile ./mobile.sh;
              };
            in
            pkgs.mkShell {
              packages = [
                pkgs.android-cli
                pkgs.maestro
                composition.androidsdk
                pkgs.jdk21
                pkgs.git
                mobile
              ]
              ++ lib.optionals analysis [
                pkgs.jadx
                pkgs.apktool
                pkgs.frida-tools
                pkgs.mitmproxy
              ]
              ++ lib.optionals nativeAnalysis [ pkgs.ghidra ]
              ++ extraPackages;

              JAVA_HOME = pkgs.jdk21.home;
              ANDROID_HOME = sdk;
              ANDROID_SDK_ROOT = sdk;
              MOBILE_IMAGE = "system-images;android-${settings.platformVersion};${imageType};x86_64";
              MOBILE_AVD = "mobile-${if analysis then "analysis" else "dev"}-${settings.platformVersion}";
              MOBILE_PORT = if analysis then "5556" else "5554";
              MOBILE_EMULATOR = if settings.emulator then "1" else "0";
              MOBILE_ANALYSIS = if analysis then "1" else "0";

              shellHook = ''
                # cmdline-tools also ships an `android` bootstrapper; prefer the pinned CLI.
                export PATH="${pkgs.android-cli}/bin:$PATH"
                export MOBILE_WORKSPACE="$PWD"
                export ANDROID_USER_HOME="$MOBILE_WORKSPACE/.mobile/android"
                export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"
                export GRADLE_USER_HOME="$MOBILE_WORKSPACE/.mobile/gradle"
                export GRADLE_OPTS="''${GRADLE_OPTS:+$GRADLE_OPTS }-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/build-tools/${settings.buildToolsVersion}/aapt2"
                mkdir -p "$ANDROID_AVD_HOME" "$GRADLE_USER_HOME"
                ${skills.shellHook}
              '';
            };
        in
        {
          _module.args.pkgs = pkgs;
          devShells = {
            default = mkMobileShell { };
            analysis = mkMobileShell { analysis = true; };
            full = mkMobileShell {
              analysis = true;
              nativeAnalysis = true;
            };
          };
          formatter = pkgs.nixfmt;
          packages.skills = skills.bundle;
          apps.skills-sources-lock = {
            type = "app";
            meta.description = "Update the pinned official Android skills";
            program = "${agentLib.mkSourceLockProgram { inherit pkgs; }}/bin/skills-sources-lock";
          };
          checks = {
            skills = pkgs.runCommand "mobile-skills-check" { } ''
              mkdir project
              cd project
              ${skills.shellHook}
              for target in .agents .codex .claude .opencode; do
                test -f "$target/skills/android-cli/SKILL.md"
                test -f "$target/skills/.agent-skills-managed.json"
              done
              touch "$out"
            '';
            scripts =
              pkgs.runCommand "mobile-script-checks"
                {
                  nativeBuildInputs = [
                    pkgs.shellcheck
                    pkgs.bash
                  ];
                }
                ''
                  shellcheck ${./mobile.sh}
                  touch "$out"
                '';
          };
        };
    };
}
