#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}
usage() {
  cat <<'HELP'
android-dev doctor                  Check SDK, CLI, Java, and KVM
android-dev avd-create              Create this shell's AVD without overwriting one
android-dev avd-start [flags...]    Start this shell's AVD in the foreground
android-dev wait [seconds]          Wait for this shell's emulator to finish booting
android-dev android [args...]       Android CLI using the pinned SDK, without metrics
android-dev create [args...]        Scaffold using a writable template-download cache
android-dev gradle [tasks...]       Run ./gradlew using the pinned SDK and JDK
android-dev test [args...]          Run Maestro tests on ANDROID_DEV_DEVICE or this shell's AVD
android-dev analyze APK OUTPUT     Hash and statically inspect an APK into a new directory

Use adb -s emulator-$ANDROID_DEV_PORT for this shell's emulator.
HELP
}
cmd="${1:-help}"
if [[ $# -gt 0 ]]; then shift; fi
case "$cmd" in
help | --help | -h)
  usage
  exit 0
  ;;
esac
: "${ANDROID_DEV_WORKSPACE:?Run inside nix develop}"
: "${ANDROID_HOME:?Run inside nix develop}"
case "$cmd" in
doctor)
  failed=0
  for tool in java adb android; do
    if ! command -v "$tool"; then failed=1; fi
  done
  [[ -d "$ANDROID_HOME/platforms" ]] || {
    echo 'SDK platforms missing'
    failed=1
  }
  printf 'SDK: %s\nAVD storage: %s\n' "$ANDROID_HOME" "$ANDROID_AVD_HOME"
  java -version
  android --no-metrics --version
  if [[ $ANDROID_DEV_EMULATOR == 1 ]]; then
    if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
      echo '/dev/kvm unavailable: enable host virtualization and kvm group access.'
      failed=1
    fi
    emulator -accel-check || failed=1
  fi
  exit "$failed"
  ;;
avd-create)
  [[ $ANDROID_DEV_EMULATOR == 1 ]] || fail 'Enable emulator in flake.nix first.'
  [[ $# == 0 ]] || fail 'Usage: android-dev avd-create'
  if [[ -e "$ANDROID_AVD_HOME/$ANDROID_DEV_AVD.ini" || -e "$ANDROID_AVD_HOME/$ANDROID_DEV_AVD.avd" ]]; then
    fail "AVD already exists: $ANDROID_DEV_AVD (kept unchanged)."
  fi
  mkdir -p "$ANDROID_AVD_HOME"
  printf 'no\n' | avdmanager create avd --name "$ANDROID_DEV_AVD" --package "$ANDROID_DEV_IMAGE"
  ;;
avd-start)
  [[ $ANDROID_DEV_EMULATOR == 1 ]] || fail 'Enable emulator in flake.nix first.'
  [[ -e "$ANDROID_AVD_HOME/$ANDROID_DEV_AVD.ini" ]] || fail 'Run android-dev avd-create first.'
  [[ -r /dev/kvm && -w /dev/kvm ]] || fail '/dev/kvm unavailable; run android-dev doctor.'
  exec emulator -avd "$ANDROID_DEV_AVD" -port "$ANDROID_DEV_PORT" -no-snapshot "$@"
  ;;
wait)
  [[ $# -le 1 ]] || fail 'Usage: android-dev wait [seconds]'
  seconds="${1:-180}"
  [[ $seconds =~ ^[1-9][0-9]*$ ]] || fail 'Timeout must be a positive integer.'
  # Bound the entire wait, including adb itself; no unbounded wait-for-device.
  # shellcheck disable=SC2016
  exec timeout "$seconds" bash -c '
      until [[ "$(adb -s "$1" shell getprop sys.boot_completed 2>/dev/null | tr -d "\r")" == 1 ]]; do
        sleep 2
      done
    ' _ "emulator-$ANDROID_DEV_PORT"
  ;;
android)
  exec android --no-metrics --sdk="$ANDROID_HOME" "$@"
  ;;
create)
  exec android --no-metrics --sdk="$ANDROID_DEV_WORKSPACE/.android-dev/bootstrap-sdk" create "$@"
  ;;
gradle)
  [[ -x ./gradlew ]] || fail 'Run from an app directory containing executable ./gradlew.'
  exec ./gradlew "$@"
  ;;
test)
  [[ $# -gt 0 ]] || fail 'Usage: android-dev test [Maestro test options] FLOW'
  exec maestro --device "${ANDROID_DEV_DEVICE:-emulator-$ANDROID_DEV_PORT}" test "$@"
  ;;
analyze)
  [[ $ANDROID_DEV_ANALYSIS == 1 ]] || fail 'Enter nix develop .#analysis first.'
  [[ $# == 2 ]] || fail 'Usage: android-dev analyze APK OUTPUT'
  apk=$(realpath -- "$1")
  [[ -f $apk ]] || fail "APK not found: $apk"
  output="$2"
  # mkdir fails for existing paths, preventing accidental replacement of evidence.
  mkdir -- "$output"
  sha256sum -- "$apk" >"$output/SHA256SUMS"
  printf '%s\n' "$apk" >"$output/source.txt"
  jadx -d "$output/jadx" "$apk"
  apktool d "$apk" -o "$output/apktool"
  ;;
*)
  usage >&2
  exit 2
  ;;
esac
