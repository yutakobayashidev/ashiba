{ inputs }:
{
  imports = [ inputs.devshell.flakeModule ];

  perSystem =
    { pkgs, system, ... }:
    let
      cli = inputs.nur-packages.packages.${system}.ghidra-cli;
      agentLib = inputs.agent-skills.lib.agent-skills;
      sources.ghidra-cli.path = cli.skillSource;
      selection = agentLib.selectSkills {
        inherit sources;
        catalog = agentLib.discoverCatalog sources;
        skills.ghidra-cli = {
          from = "ghidra-cli";
          path = "ghidra-cli";
          rewriteCommands = false;
        };
      };
      bundle = agentLib.mkBundle { inherit pkgs selection; };
      targets = pkgs.lib.genAttrs [ "agents" "codex" "claude" "opencode" ] (
        name: agentLib.defaultLocalTargets.${name} // { enable = true; }
      );
      # Do not preserve the Nix store's group when copying into a workspace.
      syncPkgs = pkgs // {
        rsync = pkgs.writeShellScriptBin "rsync" ''
          args=()
          for arg in "$@"; do
            if [[ "$arg" == -- ]]; then args+=(--no-owner --no-group); fi
            args+=("$arg")
          done
          exec ${pkgs.rsync}/bin/rsync "''${args[@]}"
        '';
      };
      skillsHook = agentLib.mkShellHook {
        pkgs = syncPkgs;
        inherit bundle targets;
      };
      projectCli = pkgs.writeShellScriptBin "ghidra-cli" ''
        export XDG_CONFIG_HOME="$GHIDRA_WORKSPACE/analysis/runtime/config"
        export XDG_CACHE_HOME="$GHIDRA_WORKSPACE/analysis/runtime/cache"
        export XDG_DATA_HOME="$GHIDRA_WORKSPACE/analysis/runtime/data"
        export GHIDRA_PROJECT_DIR="$GHIDRA_WORKSPACE/analysis/projects"
        exec ${cli}/bin/ghidra-cli "$@"
      '';
    in
    {
      devshells.default = {
        packages = [ projectCli ];
        env = [
          {
            name = "GHIDRA_WORKSPACE";
            eval = "$PWD";
          }
        ];
        devshell.startup.ghidra-skills.text = skillsHook;
      };
      packages.ghidra-cli = cli;
      checks.ghidra-skills = pkgs.runCommand "ghidra-cli-skills-check" { } ''
        mkdir project
        cd project
        ${skillsHook}
        for target in .agents .codex .claude .opencode; do
          test -f "$target/skills/ghidra-cli/SKILL.md"
          test -d "$target/skills/ghidra-cli/references"
        done
        touch "$out"
      '';
    };
}
