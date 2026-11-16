{
  description = "Composable Android development and reverse engineering";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    ashiba.url = "github:yutakobayashidev/ashiba";
  };
  outputs =
    inputs:
    let
      modules = inputs.ashiba.flakeModules;
      environment =
        extraModules:
        inputs.flake-parts.lib.mkFlake { inherit inputs; } {
          systems = [ "x86_64-linux" ];
          imports = [ modules.android ] ++ extraModules;
          perSystem.ashiba.android = {
            acceptLicense = true;
            platformVersion = "36";
            buildToolsVersion = "36.0.0";
            # Disable for physical devices or build-only CI.
            emulator = true;
            # sdk = { includeNDK = true; ndkVersions = [ "..." ]; };
          };
        };
      development = environment [ ];
      analysis = environment [ modules.reverse-android ];
      full = environment [
        modules.reverse-android
        modules.reverse-native
      ];
    in
    development
    // {
      devShells.x86_64-linux = {
        default = development.devShells.x86_64-linux.default;
        analysis = analysis.devShells.x86_64-linux.default;
        full = full.devShells.x86_64-linux.default;
      };
      checks.x86_64-linux = development.checks.x86_64-linux // {
        analysis-skills = analysis.checks.x86_64-linux.skills;
        full-skills = full.checks.x86_64-linux.skills;
      };
    };
}
