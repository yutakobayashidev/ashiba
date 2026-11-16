{ inputs }:
{
  imports = [ (import ./skills.nix { inherit inputs; }) ];
  perSystem =
    { lib, pkgs, ... }:
    let
      # Rebuild the pinned NUR library with this shell's Python interpreter.
      ptrlib = pkgs.callPackage (inputs.nur-packages + "/pkgs/ptrlib") { };
      python = pkgs.python3.withPackages (ps: [
        ps.pwntools
        ps.ropper
        ptrlib
      ]);
    in
    {
      ashiba.skills = {
        sources.pwn.path = ../skills;
        selection.pwn = {
          from = "pwn";
          path = "pwn";
          rewriteCommands = false;
        };
      };
      devshells.default.packages = with pkgs; [
        gdb
        gef
        (lib.lowPrio python)
        one_gadget
        pwninit
        checksec
        binutils
        patchelf
        file
        qemu
        strace
        ltrace
      ];
    };
}
