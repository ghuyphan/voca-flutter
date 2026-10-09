#!/usr/bin/env bash
# ==============================================================================
# VOCA Commercial Footage Capture Script
# Automates clean 60fps screen recording from connected Android Emulator or iOS Simulator
# ==============================================================================
set -euo pipefail

OUTPUT_DIR="$(pwd)/assets/commercial_footage"
mkdir -p "$OUTPUT_DIR"

ADB="/Users/huyphan/Library/Android/sdk/platform-tools/adb"
if [ ! -f "$ADB" ]; then
  ADB="adb"
fi

echo "🎬 [1/3] Preparing clean demo status bar on emulator..."
"$ADB" shell settings put global sysui_demo_mode 1 || true
"$ADB" shell am broadcast -a com.android.systemui.demo -e command enter || true
"$ADB" shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941 || true
"$ADB" shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false || true
"$ADB" shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 || true

echo "🎥 [2/3] Starting 1080x2400 60fps screen recording (15s)..."
"$ADB" shell "screenrecord --size 1080x2400 --bit-rate 16000000 --time-limit 15 /sdcard/voca_commercial_raw.mp4" &
RECORD_PID=$!

echo "⏳ Recording in progress. Perform app walkthrough now or wait for automated completion..."
wait $RECORD_PID || true

echo "📥 [3/3] Pulling raw footage to $OUTPUT_DIR..."
"$ADB" pull /sdcard/voca_commercial_raw.mp4 "$OUTPUT_DIR/voca_commercial_raw.mp4"
"$ADB" shell rm /sdcard/voca_commercial_raw.mp4

# Clean up demo mode
"$ADB" shell am broadcast -a com.android.systemui.demo -e command exit || true

echo "✅ Footage successfully saved to: $OUTPUT_DIR/voca_commercial_raw.mp4"
