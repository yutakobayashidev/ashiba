---
name: firmware-workflow
description: Build and validate Arduino or PlatformIO firmware in this project; use when editing sketches, board configuration or firmware dependencies.
---

# Firmware development

Identify the board and FQBN or PlatformIO board ID before choosing a toolchain. Pin Arduino cores and libraries in sketch.yaml or PlatformIO platforms and libraries in platformio.ini: flake.lock pins only host tools. Compile before uploading. Select the actual port explicitly, preferring /dev/serial/by-id on Linux. Keep authorization scoped to the identified device; shell entry never flashes it. Distinguish build results from behavior verified on hardware.

Keep generated outputs under build/ or exports/. Report which checks ran and what remains unverified.
