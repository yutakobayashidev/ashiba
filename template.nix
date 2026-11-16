{ inputs }:
{
  mobile = {
    path = ./mobile;
    description = "Linux Android development, Maestro E2E tests, and APK analysis with project-local agent skills";
  };
  diy = {
    path = ./diy;
    description = "Composable firmware, CAD, PCB and 3D printing environments with project-local agent skills";
  };
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
