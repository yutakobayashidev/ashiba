{ inputs }:
{
  imports = [ (import ./skills.nix { inherit inputs; }) ];
  perSystem =
    {
      config,
      lib,
      pkgs,
      system,
      ...
    }:
    let
      cfg = config.ashiba.android;
      analysis = config.ashiba.reverseAndroid;
      # SDK license acceptance stays explicit in the consuming project.
      androidPkgs = import pkgs.path {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = cfg.acceptLicense;
        };
      };
      agentLib = inputs.agent-skills.lib.agent-skills;
      sources = agentLib.sourcesFromLock {
        manifestsDir = ../registry/sources;
        lockFile = ../registry/sources.lock.json;
      };
      catalog = agentLib.discoverCatalog sources;
      names = map (skill: builtins.baseNameOf skill.relPath) (builtins.attrValues catalog);
      imageType = if analysis then "default" else "google_apis";
      composition = androidPkgs.androidenv.composeAndroidPackages (
        {
          platformVersions = [ cfg.platformVersion ];
          buildToolsVersions = [ cfg.buildToolsVersion ];
          toolsVersion = null;
          includeCmake = false;
          includeNDK = false;
          includeEmulator = cfg.emulator;
          includeSystemImages = cfg.emulator;
          systemImageTypes = [ imageType ];
          abiVersions = [ "x86_64" ];
        }
        // cfg.sdk
      );
      sdk = "${composition.androidsdk}/libexec/android-sdk";
      android-dev = pkgs.writeShellApplication {
        name = "android-dev";
        runtimeInputs = [
          pkgs.coreutils
          androidPkgs.android-cli
        ];
        text = builtins.readFile ./android-dev.sh;
      };
    in
    {
      options.ashiba.android = {
        acceptLicense = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Accept the Android SDK license.";
        };
        platformVersion = lib.mkOption {
          type = lib.types.str;
          default = "36";
        };
        buildToolsVersion = lib.mkOption {
          type = lib.types.str;
          default = "36.0.0";
        };
        emulator = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        sdk = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "Additional composeAndroidPackages settings (NDK, CMake, etc.).";
        };
      };
      config = {
        ashiba.skills = {
          inherit sources;
          selection =
            assert builtins.length names == builtins.length (lib.unique names);
            lib.mapAttrs' (
              _: skill:
              lib.nameValuePair (builtins.baseNameOf skill.relPath) {
                from = "android";
                path = skill.relPath;
                rewriteCommands = false;
              }
            ) catalog;
        };
        devshells.default = {
          packages = [
            androidPkgs.android-cli
            androidPkgs.maestro
            # The SDK also exports android and adb; prefer the dedicated CLIs.
            (lib.setPrio 20 composition.androidsdk)
            pkgs.jdk21
            pkgs.git
            android-dev
          ];
          env = [
            {
              name = "MAESTRO_CLI_NO_ANALYTICS";
              value = "1";
            }
            {
              name = "MAESTRO_DISABLE_UPDATE_CHECK";
              value = "true";
            }
            {
              name = "JAVA_HOME";
              value = pkgs.jdk21.home;
            }
            {
              name = "ANDROID_HOME";
              value = sdk;
            }
            {
              name = "ANDROID_SDK_ROOT";
              value = sdk;
            }
            {
              name = "ANDROID_DEV_IMAGE";
              value = "system-images;android-${cfg.platformVersion};${imageType};x86_64";
            }
            {
              name = "ANDROID_DEV_AVD";
              value = "android-dev-${if analysis then "analysis" else "dev"}-${cfg.platformVersion}";
            }
            {
              name = "ANDROID_DEV_PORT";
              value = if analysis then "5556" else "5554";
            }
            {
              name = "ANDROID_DEV_EMULATOR";
              value = if cfg.emulator then "1" else "0";
            }
            {
              name = "ANDROID_DEV_ANALYSIS";
              value = if analysis then "1" else "0";
            }
          ];
          devshell.startup.android.text = ''
            export PATH="${androidPkgs.android-cli}/bin:$PATH"
            export ANDROID_DEV_WORKSPACE="$PWD"
            export ANDROID_USER_HOME="$ANDROID_DEV_WORKSPACE/.android-dev/android"
            export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"
            export GRADLE_USER_HOME="$ANDROID_DEV_WORKSPACE/.android-dev/gradle"
            export GRADLE_OPTS="''${GRADLE_OPTS:+$GRADLE_OPTS }-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/build-tools/${cfg.buildToolsVersion}/aapt2"
            export MAESTRO_OPTS="''${MAESTRO_OPTS:+$MAESTRO_OPTS }-Duser.home=\"$ANDROID_DEV_WORKSPACE/.android-dev/maestro-home\""
            mkdir -p "$ANDROID_AVD_HOME" "$GRADLE_USER_HOME" "$ANDROID_DEV_WORKSPACE/.android-dev/maestro-home"
          '';
        };
        checks.android-scripts =
          pkgs.runCommand "android-dev-script-checks" { nativeBuildInputs = [ pkgs.shellcheck ]; }
            ''
              shellcheck ${./android-dev.sh}
              touch "$out"
            '';
      };
    };
}
