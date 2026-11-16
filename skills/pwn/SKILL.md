---
name: pwn
description: Debug native CTF binaries and build local solvers using GDB, GEF, pwntools, ptrlib, and ROP tools. Use for native pwn challenges and reproducible local binary investigation.
---

# Native CTF workflow

Record the target hash, architecture, interpreter and supplied libc/loader.
Keep originals unchanged. Use readelf and the installed checksec command to
inspect the ELF; check its help because standalone checksec and `pwn checksec`
have different interfaces. Host libc is not a substitute for a supplied libc.

Use `gdb -nx` for predictable batch debugging and `gef -nx` for GEF's views.
Do not source challenge-provided debugger scripts without inspecting them.
Start the target as the debugger's child when possible. If ptrace is blocked,
report the actual restriction; do not disable host-wide ptrace policy.

Use the shell's Python for pwntools, ptrlib and Ropper. Set architecture and
endianness from the target, and give process/socket reads finite timeouts.
Reproduce behavior locally before treating a solver as verified. Distinguish
a crash, controlled input, and a demonstrated result; retain the command and
observed output that support each finding.

ROPgadget and Ropper locate candidate gadgets. Verify instruction boundaries,
side effects and addresses against the loaded binary and actual memory layout.
one_gadget results have constraints that must be checked in the runtime context.

pwninit and patchelf can change files. Use a separate working copy and inspect
the resulting interpreter/RPATH. pwninit may download matching runtime files;
record what was used. QEMU user mode may need an explicit guest library prefix.
The Nix shell is a tool environment, not isolation for an untrusted executable.

Use the full shell for Ghidra CLI and its skill. Stop the project's bridge when
done or before switching its runtime. Preserve the distinction between static
inference and observations from GDB, strace, or ltrace.
