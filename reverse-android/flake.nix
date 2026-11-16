{
  description = "Project-local Android reverse engineering without the SDK";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    ashiba.url = "github:yutakobayashidev/ashiba";
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ inputs.ashiba.flakeModules.reverse-android ];
      # Add inputs.ashiba.flakeModules.reverse-native above for ELF/.so analysis.
    };
}
