{ inputs }:
{
  imports = [ (import ./skills.nix { inherit inputs; }) ];
  perSystem =
    { pkgs, system, ... }:
    let
      cli = inputs.nur-packages.packages.${system}.ghidra-cli;
      projectCli = pkgs.writeShellScriptBin "ghidra-cli" ''
        export XDG_CONFIG_HOME="$GHIDRA_WORKSPACE/analysis/runtime/config"
        export XDG_CACHE_HOME="$GHIDRA_WORKSPACE/analysis/runtime/cache"
        export XDG_DATA_HOME="$GHIDRA_WORKSPACE/analysis/runtime/data"
        export GHIDRA_PROJECT_DIR="$GHIDRA_WORKSPACE/analysis/projects"
        exec ${cli}/bin/ghidra-cli "$@"
      '';
    in
    {
      ashiba.skills = {
        sources.ghidra-cli.path = cli.skillSource;
        selection.ghidra-cli = {
          from = "ghidra-cli";
          path = "ghidra-cli";
          rewriteCommands = false;
        };
      };
      devshells.default = {
        packages = [ projectCli ];
        env = [
          {
            name = "GHIDRA_WORKSPACE";
            eval = "$PWD";
          }
        ];
      };
      packages.ghidra-cli = cli;
    };
}
