# ashiba

Project templates collection. Dependencies are automatically updated.

## Usage

```bash
nix flake init -t github:yutakobayashidev/ashiba#<name>
```

## Templates

| Name | Description |
|---|---|
| `android` | [Android SDK, Maestro, APK analysis, and agent skills (Linux x86_64)](android/README.md) |
| `firmware` | [Arduino and PlatformIO firmware development](firmware/README.md) |
| `cad` | [Mechanical design with FreeCAD and OpenSCAD](cad/README.md) |
| `pcb` | [PCB design and validation with KiCad](pcb/README.md) |
| `printing` | [3D print preparation with PrusaSlicer](printing/README.md) |
| `reverse-android` | [APK analysis with JADX, Apktool, Frida, and ADB](reverse-android/README.md) |
| `reverse-native` | [Ghidra CLI and matching agent skill](reverse-native/README.md) |
| `flake-devenv` | Nix flake with devenv, treefmt, and git-hooks |
| `next` | Next.js with Tailwind CSS and shadcn/ui |
| `next-firebase-auth-e2e` | Next.js App Router with Firebase Auth and E2E testing |
| `moonbit` | [MoonBit project with devshell](https://github.com/moonbit-community/moonbit-overlay) |
| `web-app` | [Web app template by hiroppy](https://github.com/hiroppy/web-app-template) |

For language-specific flake templates, see also [the-nix-way/dev-templates](https://github.com/the-nix-way/dev-templates).

## Composable analysis environments

Import `flakeModules.android`, `flakeModules.reverse-android`, or
`flakeModules.reverse-native` into a flake-parts project. They contribute tools
to `perSystem.devshells.default` and collect skills into one synchronization hook.
The Android template provides development, APK analysis, and combined native
analysis shells; the reverse-android template works without an SDK.

Maintainers update the official Android skill registry at the repository root
with `nix run .#skills-sources-lock`, then commit `registry/` together. Consumers
update the pinned ashiba input. Ghidra skills follow the CLI source revision.

Project-owned skills can join the same bundle:

```nix
perSystem.ashiba.skills = {
  sources.project.path = ./skills;
  selection.my-workflow = {
    from = "project";
    path = "my-workflow";
    rewriteCommands = false;
  };
};
```

Keep originals under `skills/my-workflow/`. The generated agent skill directories
are mirrors of the selected bundle: switching shells removes skills that are no
longer selected, including files manually placed in those generated directories.
