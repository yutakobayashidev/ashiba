{
  description = "Project-local native CTF debugging and binary analysis";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    ashiba.url = "github:yutakobayashidev/ashiba";
  };
  outputs =
    inputs:
    let
      environment =
        extraModules:
        inputs.flake-parts.lib.mkFlake { inherit inputs; } {
          systems = [ "x86_64-linux" ];
          imports = [ inputs.ashiba.flakeModules.pwn ] ++ extraModules;
        };
      pwn = environment [ ];
      full = environment [ inputs.ashiba.flakeModules.reverse-native ];
    in
    pwn
    // {
      devShells.x86_64-linux = {
        default = pwn.devShells.x86_64-linux.default;
        full = full.devShells.x86_64-linux.default;
      };
      checks.x86_64-linux = pwn.checks.x86_64-linux // {
        full-skills = full.checks.x86_64-linux.skills;
      };
    };
}
