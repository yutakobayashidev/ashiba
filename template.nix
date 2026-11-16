{ inputs }:
{
  android = {
    path = ./android;
    description = "Linux Android development, Maestro E2E tests, and APK analysis with project-local agent skills";
  };
  firmware = {
    path = ./firmware;
    description = "Arduino and PlatformIO firmware development with project-local agent skills";
  };
  cad = {
    path = ./cad;
    description = "Mechanical design with FreeCAD and OpenSCAD with project-local agent skills";
  };
  pcb = {
    path = ./pcb;
    description = "PCB design and validation with KiCad with project-local agent skills";
  };
  printing = {
    path = ./printing;
    description = "3D print preparation with PrusaSlicer with project-local agent skills";
  };
  reverse-android = {
    path = ./reverse-android;
    description = "JADX, Apktool, Frida, and ADB for Android reverse engineering";
  };
  reverse-native = {
    path = ./reverse-native;
    description = "Ghidra CLI and matching agent skill for native reverse engineering";
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
