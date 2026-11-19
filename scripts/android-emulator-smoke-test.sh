#!/usr/bin/env bash
set -euo pipefail

APK_PATH="${1:?Usage: android-emulator-smoke-test.sh path/to.apk}"
PACKAGE="com.tigerchat.tigercity3d"
SCREENSHOT="/tmp/tiger-city-launch.png"
CURRENT_STAGE="setup"
DIAGNOSTICS_DIR="build/android-smoke-diagnostics"
mkdir -p "$DIAGNOSTICS_DIR"
trap 'status=$?; if [ "$status" -ne 0 ]; then cp "$SCREENSHOT" "$DIAGNOSTICS_DIR/failure-screen.png" 2>/dev/null || true; printf '%s\n' "$CURRENT_STAGE" > "$DIAGNOSTICS_DIR/failure-stage.txt"; adb logcat -d -t 5000 > "$DIAGNOSTICS_DIR/logcat.txt" 2>/dev/null || true; adb shell dumpsys activity activities > "$DIAGNOSTICS_DIR/activities.txt" 2>/dev/null || true; adb shell dumpsys SurfaceFlinger > "$DIAGNOSTICS_DIR/surfaceflinger.txt" 2>/dev/null || true; fi; exit "$status"' EXIT

test -s "$APK_PATH"
adb wait-for-device

echo "Waiting for a stable Android boot and core system services..."
ready_streak=0
for attempt in $(seq 1 180); do
  booted="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\\r' || true)"
  package_service="$(adb shell service check package 2>/dev/null || true)"
  activity_service="$(adb shell service check activity 2>/dev/null || true)"
  device_state="$(adb get-state 2>/dev/null || true)"
  if [ "$device_state" = "device" ] && [ "$booted" = "1" ] && \
     printf '%s' "$package_service" | grep -q 'found' && \
     printf '%s' "$activity_service" | grep -q 'found'; then
    ready_streak=$((ready_streak + 1))
    echo "Core services healthy ($ready_streak/10 consecutive checks; attempt $attempt/180)."
    if [ "$ready_streak" -ge 10 ]; then
      break
    fi
  else
    ready_streak=0
    echo "Waiting for services ($attempt/180): state=$device_state boot=$booted package='$package_service' activity='$activity_service'"
  fi
  sleep 2
done
if [ "$ready_streak" -lt 10 ]; then
  echo "Android core services did not remain healthy for 20 seconds."
  adb devices -l || true
  adb shell getprop sys.boot_completed || true
  adb shell service check package || true
  adb shell service check activity || true
  adb logcat -d -t 2000 | grep -iE 'PackageManager|system_server|Watchdog|FATAL|AndroidRuntime' | tail -n 200 || true
  exit 1
fi

# Avoid adb's incremental-install path: it can destabilize package installation
# on a freshly booted hosted emulator. Stream the APK after system services settle.
adb install --no-incremental -r "$APK_PATH"

# The AOSP emulator has no carrier/data service; disable Wi-Fi when available.
adb shell cmd wifi set-wifi-enabled disabled >/dev/null 2>&1 || true

wait_for_foreground() {
  for attempt in $(seq 1 60); do
    if adb shell dumpsys activity activities 2>/dev/null | grep -E 'mResumedActivity|topResumedActivity' | grep -q "$PACKAGE"; then
      return 0
    fi
    sleep 1
  done
  echo "Game did not reach the foreground within 60 seconds."
  adb shell dumpsys activity activities | tail -n 80 || true
  adb logcat -d -t 500 | grep -iE 'fatal exception|AndroidRuntime|Godot|tiger' | tail -n 100 || true
  return 1
}

launch_and_check() {
  CURRENT_STAGE="${1:?stage name required}"
  SCREENSHOT="/tmp/tiger-city-${CURRENT_STAGE}.png"
  adb shell monkey -p "$PACKAGE" 1 >/dev/null
  wait_for_foreground
  adb shell pidof "$PACKAGE" >/dev/null
  sleep 8
  adb exec-out screencap -p > "$SCREENSHOT"
  test -s "$SCREENSHOT"
  cp "$SCREENSHOT" "$DIAGNOSTICS_DIR/${CURRENT_STAGE}.png"
  python3 - "$SCREENSHOT" <<'PY'
import sys
from PIL import Image, ImageStat
im = Image.open(sys.argv[1]).convert("RGB")
w, h = im.size
assert w > h, f"Expected landscape launch, got {w}x{h}"
im = im.crop((int(w*.08), int(h*.08), int(w*.92), int(h*.92)))
pixels = list(im.resize((160, 90)).getdata())
white = sum(1 for p in pixels if min(p) >= 245) / len(pixels)
black = sum(1 for p in pixels if max(p) <= 10) / len(pixels)
colors = len(set(pixels))
stddev = sum(ImageStat.Stat(im).stddev) / 3
print(f"Launch screenshot: {w}x{h}; sampled colors={colors}; mean channel stddev={stddev:.1f}; white={white:.3%}; black={black:.3%}")
assert colors > 30 and stddev > 8, "Screen appears blank or nearly uniform"
assert white < .995 and black < .50, "Screen is almost entirely white or more than half black"
PY
}

FAILURES=0

echo "Offline cold launch"
if launch_and_check cold_launch; then
  echo "PASS: cold launch"
else
  echo "FAIL: cold launch"
  FAILURES=$((FAILURES + 1))
fi

# Repeat the lifecycle transition three times. Continue after a failed screenshot
# so later cycles and the force-stop relaunch still produce useful diagnostics.
for cycle in 1 2 3; do
  stage="background_resume_${cycle}"
  echo "Background/resume cycle ${cycle}/3"
  adb shell input keyevent 3
  sleep 3
  if launch_and_check "$stage"; then
    echo "PASS: $stage"
  else
    echo "FAIL: $stage"
    FAILURES=$((FAILURES + 1))
  fi
  adb logcat -d -t 2500 > "$DIAGNOSTICS_DIR/${stage}-logcat.txt" 2>/dev/null || true
  adb shell dumpsys activity activities > "$DIAGNOSTICS_DIR/${stage}-activities.txt" 2>/dev/null || true
  adb shell dumpsys SurfaceFlinger > "$DIAGNOSTICS_DIR/${stage}-surfaceflinger.txt" 2>/dev/null || true
done

echo "Force-stop and cold relaunch"
adb shell am force-stop "$PACKAGE"
sleep 2
if launch_and_check force_stop_relaunch; then
  echo "PASS: force-stop relaunch"
else
  echo "FAIL: force-stop relaunch"
  FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -ne 0 ]; then
  echo "Android lifecycle smoke tests failed: $FAILURES stage(s) failed."
  exit 1
fi
echo "Offline cold launch, three background/resume cycles, and force-stop relaunch passed."
