{
  description = "Project templates collection";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    moonbit-overlay.url = "github:moonbit-community/moonbit-overlay";
    web-app-template = {
      url = "github:hiroppy/web-app-template";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ ];

      flake = {
        templates = import ./template.nix { inherit inputs; };
      };
    };
}
