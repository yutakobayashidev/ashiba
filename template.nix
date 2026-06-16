{ inputs }:
{
  flake-devenv = {
    path = ./flake-devenv;
    description = "Nix flake with devenv, treefmt, and git-hooks";
  };
  next = {
    path = ./next;
    description = "Next.js with Tailwind CSS and shadcn/ui";
  };
  next-firebase-auth-e2e = {
    path = ./next-firebase-auth-e2e;
    description = "Next.js App Router with Firebase Auth and E2E testing";
  };
  agent-web-infra = {
    path = ./agent-web-infra;
    description = "An AI-agent-ready Node.js, Terraform, and Google Cloud development environment with MCP servers and Agents skills";
  };
  moonbit = inputs.moonbit-overlay.templates.default;
  web-app = {
    path = inputs.web-app-template;
    description = "Web app template by hiroppy";
  };
}
