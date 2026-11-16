{ inputs }:
{
  imports = [ inputs.devshell.flakeModule ];
  key = "ashiba-skills";
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ashiba.skills;
      agentLib = inputs.agent-skills.lib.agent-skills;
      selection = agentLib.selectSkills {
        inherit (cfg) sources;
        catalog = agentLib.discoverCatalog cfg.sources;
        skills = cfg.selection;
      };
      bundle = agentLib.mkBundle { inherit pkgs selection; };
      targets = lib.genAttrs [ "agents" "codex" "claude" "opencode" ] (
        name: agentLib.defaultLocalTargets.${name} // { enable = true; }
      );
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
      hook = agentLib.mkShellHook {
        pkgs = syncPkgs;
        inherit bundle targets;
      };
    in
    {
      options.ashiba = {
        reverseAndroid = lib.mkOption {
          type = lib.types.bool;
          default = false;
          internal = true;
        };
        skills = {
          sources = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
          selection = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
        };
      };
      config = {
        devshells.default.devshell.startup.ashiba-skills.text = hook;
        packages.skills = bundle;
        checks.skills = pkgs.runCommand "ashiba-skills-check" { } ''
          mkdir project
          cd project
          ${hook}
          for target in .agents .codex .claude .opencode; do
            ${lib.concatMapStringsSep "\n" (name: ''test -f "$target/skills/${name}/SKILL.md"'') (
              builtins.attrNames cfg.selection
            )}
            test -f "$target/skills/.agent-skills-managed.json"
          done
          touch "$out"
        '';
      };
    };
}
