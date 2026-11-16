---
name: pcb-workflow
description: Design and validate KiCad circuits and PCBs; use when editing schematics, board layouts, libraries or fabrication outputs.
---

# PCB design

Preserve KiCad project, schematic, PCB and library sources. Record electrical and mechanical constraints before editing. Run ERC and DRC with the installed KiCad version and report violations or explicit waivers before exporting fabrication files. Gerber and drill files are derived artifacts; do not treat successful export as electrical verification.

Keep generated outputs under build/ or exports/. Report which checks ran and what remains unverified.
