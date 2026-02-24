{
  description = "Project templates collection";

  outputs =
    { self, ... }:
    {
      templates = {
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
      };
    };
}
