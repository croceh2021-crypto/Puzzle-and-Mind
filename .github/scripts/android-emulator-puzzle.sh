#!/usr/bin/env bash
set -Eeuo pipefail

RESULTS_DIR="test-results"
PACKAGE_ID="org.puzzleandmind.game"
APK="build/PuzzleAndMind-debug.apk"
mkdir -p "$RESULTS_DIR"

collect_diagnostics() {
  adb logcat -d -v time > "$RESULTS_DIR/logcat.txt" 2>&1 || true
  adb shell dumpsys activity activities > "$RESULTS_DIR/activities.txt" 2>&1 || true
  adb shell pidof "$PACKAGE_ID" > "$RESULTS_DIR/game-pid.txt" 2>&1 || true
}

echo "Waiting for Android emulator"
adb wait-for-device
boot_state=""
for attempt in $(seq 1 90); do
  boot_state="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
  [[ "$boot_state" == "1" ]] && break
  sleep 2
done
[[ "$boot_state" == "1" ]] || { echo "Android emulator did not finish booting"; exit 1; }

adb shell wm size 720x1280
adb logcat -c

echo "Installing Puzzle & Mind APK"
test -s "$APK"
adb install -r "$APK"

echo "Launching Puzzle & Mind"
adb shell am start -W -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p "$PACKAGE_ID" > "$RESULTS_DIR/launch.txt"
cat "$RESULTS_DIR/launch.txt"
sleep 8

pid="$(adb shell pidof "$PACKAGE_ID" | tr -d '\r' || true)"
if [[ -z "$pid" ]]; then
  collect_diagnostics
  echo "Puzzle & Mind process exited after launch"
  exit 1
fi

adb exec-out screencap -p > "$RESULTS_DIR/01-home-screen.png"
test -s "$RESULTS_DIR/01-home-screen.png"

# Home screen: tap the primary "ابدأ اللعب" button.
echo "Tapping the primary play button"
adb shell input tap 360 890
sleep 4
adb exec-out screencap -p > "$RESULTS_DIR/02-world-selection.png"
test -s "$RESULTS_DIR/02-world-selection.png"

# World selection: choose the second card, Spot the Differences.
echo "Selecting Spot the Differences world"
adb shell input tap 360 285
sleep 4
adb exec-out screencap -p > "$RESULTS_DIR/03-spot-levels.png"
test -s "$RESULTS_DIR/03-spot-levels.png"

# Stage grid: open the first available level.
echo "Opening the first available spot-the-differences level"
adb shell input tap 90 195
sleep 6
adb exec-out screencap -p > "$RESULTS_DIR/04-spot-puzzle-level-1.png"
test -s "$RESULTS_DIR/04-spot-puzzle-level-1.png"

# Exercise three image touch locations in the lower image. The screenshots
# preserve evidence even if a layout change moves one of these targets.
adb shell input tap 120 590
sleep 1
adb shell input tap 520 565
sleep 1
adb shell input tap 350 635
sleep 3
adb exec-out screencap -p > "$RESULTS_DIR/05-after-difference-taps.png"
test -s "$RESULTS_DIR/05-after-difference-taps.png"

collect_diagnostics

if grep -E -i "FATAL EXCEPTION|Fatal signal|SIGSEGV|Process $PACKAGE_ID.*(died|has died)" "$RESULTS_DIR/logcat.txt"; then
  echo "Fatal Android/app error found"
  exit 1
fi
if grep -E -i "SCRIPT ERROR:|Failed to load script .* with error|Parse Error:" "$RESULTS_DIR/logcat.txt"; then
  echo "Godot script error found"
  exit 1
fi
if ! adb shell pidof "$PACKAGE_ID" >/dev/null 2>&1; then
  echo "Game process is no longer running"
  exit 1
fi

echo "PASS: APK installed and launched; home, world, level and puzzle screenshots captured; touch events sent; app remained alive without fatal/script errors."
