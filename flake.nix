{
  description = "Project templates collection";

  inputs = {
    nur-packages.url = "github:yutakobayashidev/nur-packages";
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moonbit-overlay.url = "github:moonbit-community/moonbit-overlay";
    web-app-template = {
      url = "github:hiroppy/web-app-template";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      imports = [ inputs.git-hooks.flakeModule ];

      perSystem =
        { config, pkgs, ... }:
        {
          pre-commit = {
            check.enable = false;
            settings.hooks = {
              convco.enable = true;
            };
          };

          devShells.default = pkgs.mkShellNoCC {
            shellHook = config.pre-commit.installationScript;
          };
        };

      flake = {
        flakeModules.reverse-native = import ./modules/reverse-native.nix { inherit inputs; };
        templates = import ./template.nix { inherit inputs; };
      };
    };
}
