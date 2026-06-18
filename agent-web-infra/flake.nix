{
  description = "An AI-agent-ready Node.js, Terraform, and Google Cloud development environment with MCP servers and Agents skills";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    agent-skills-nix.url = "github:Kyure-A/agent-skills-nix";
    google-skills = {
      url = "github:google/skills";
      flake = false;
    };
    vercel-skills = {
      url = "github:vercel-labs/skills";
      flake = false;
    };
    vercel-next-skills = {
      url = "github:vercel-labs/next-skills";
      flake = false;
    };
    hono-skill = {
      url = "github:yusukebe/hono-skill";
      flake = false;
    };
    ui-ux-pro-max-skill = {
      url = "github:nextlevelbuilder/ui-ux-pro-max-skill";
      flake = false;
    };
    modern-web-guidance = {
      url = "github:GoogleChrome/modern-web-guidance";
      flake = false;
    };
    nur-packages = {
      url = "github:yutakobayashidev/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hashicorp-agent-skills = {
      url = "github:hashicorp/agent-skills";
      flake = false;
    };
    actrun = {
      url = "github:mizchi/actrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.mcp-servers-nix.flakeModule ];
      systems = supportedSystems;

      flake = {
        overlays.default = final: prev: rec {
          nodejs = prev.nodejs;
        };
      };

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "terraform" ];
              permittedInsecurePackages = [
                "python3.13-ecdsa-0.19.2"
              ];
            };
            overlays = [ inputs.self.overlays.default ];
          };

          mcp-servers = {
            programs.terraform.enable = true;
            settings.servers = {
              mdn = {
                type = "http";
                url = "https://mcp.mdn.mozilla.net/";
              };
            };
            flavors = {
              "claude-code".enable = true;
              opencode.enable = true;
            };
          };

          devShells.default = pkgs.mkShellNoCC {
            shellHook =
              let
                agentLib = inputs.agent-skills-nix.lib.agent-skills;
                sources = {
                  google-cloud = {
                    path = inputs.google-skills + "/skills/cloud";
                  };
                  vercel = {
                    path = inputs.vercel-skills;
                    subdir = "skills";
                  };
                  vercel-next = {
                    path = inputs.vercel-next-skills;
                    subdir = "skills";
                  };
                  hono = {
                    path = inputs.hono-skill;
                    subdir = "skills";
                  };
                  ui-ux-pro-max = {
                    path = inputs.ui-ux-pro-max-skill + "/.claude/skills";
                  };
                  modern-web-guidance = {
                    path = inputs.modern-web-guidance + "/skills/modern-web-guidance";
                  };
                  hashicorp = {
                    path = inputs.hashicorp-agent-skills;
                  };
                  actrun = {
                    path = inputs.actrun.outPath;
                    subdir = ".claude/skills";
                  };
                };
                catalog = agentLib.discoverCatalog sources;
                allowlist = agentLib.allowlistFor {
                  inherit catalog sources;
                  enableAll = true;
                };
                selection = agentLib.selectSkills {
                  inherit catalog allowlist sources;
                  skills = { };
                };
                bundle = agentLib.mkBundle { inherit pkgs selection; };
                localTargets = builtins.mapAttrs (
                  _: target:
                  target
                  // {
                    enable = true;
                  }
                ) agentLib.defaultLocalTargets;
              in
              config.mcp-servers.shellHook
              + agentLib.mkShellHook {
                inherit pkgs bundle;
                targets = localTargets;
              };
            packages = with pkgs; [
              checkov
              google-cloud-sdk
              inframap
              nodejs
              pnpm
              (terraform.withPlugins (plugins: [ plugins.hashicorp_google ]))
              tflint
              trivy
              inputs.actrun.packages.${system}.default
              inputs.nur-packages.packages.${system}.pike
              self.formatter.${system}
            ];
          };

          formatter = pkgs.nixfmt-tree;
        };
    };
}
