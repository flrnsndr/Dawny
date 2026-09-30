#!/usr/bin/env bash
#
# Generates standardized App Store screenshots for both English and German.
#
# Runs the DawnyUITests/ScreenshotTests suite once. The suite contains two
# test methods (testTakeScreenshotsEN, testTakeScreenshotsDE) that each launch
# the app with the appropriate locale via XCUIApplication.launchEnvironment.
# The app is launched with `--screenshots`, which triggers ScreenshotSeeder to
# wipe existing tasks and insert deterministic content per locale.
#
# Four screenshots are captured per locale (Backlog, Today, Archive with swipe,
# and the empty Today after the reset). The status bar is pinned to 9:41 with
# full signal for the run and cleared afterwards.
#
# The widget screenshot (04_Widgets.png) is taken by hand. Afterwards
# ./scripts/render-store-screenshots.sh turns the raw captures into the
# captioned store images.
#
# Usage:
#   ./scripts/take-screenshots.sh
#
# Output:
#   screenshots/en/0{1,2,3,5}_*.png
#   screenshots/de/0{1,2,3,5}_*.png
#
# Requires: Xcode with the "iPhone 17 Pro Max" simulator (addressed by UDID,
# override with SIMULATOR_ID).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

SIMULATOR_ID="${SIMULATOR_ID:-8252A958-E94C-4707-BCD7-AF8F4ABED733}"
PROJECT="Dawny.xcodeproj"
SCHEME="Dawny"
OUTPUT_ROOT="$PROJECT_ROOT/screenshots"
TEMP_ROOT="/tmp/dawny-screenshots"

echo "📸 Dawny App Store screenshot run"
echo "   Simulator: $SIMULATOR_ID"
echo "   Output:    $OUTPUT_ROOT"
echo

rm -rf "$TEMP_ROOT"
mkdir -p "$TEMP_ROOT/en" "$TEMP_ROOT/de" "$OUTPUT_ROOT/en" "$OUTPUT_ROOT/de"

xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
xcrun simctl bootstatus "$SIMULATOR_ID" -b > /dev/null
xcrun simctl status_bar "$SIMULATOR_ID" override \
    --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100
trap 'xcrun simctl status_bar "$SIMULATOR_ID" clear' EXIT

echo "→ Running ScreenshotTests (EN + DE)…"

set +e
xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -testPlan Screenshots \
    -resultBundlePath "$TEMP_ROOT/result.xcresult" \
    > "$TEMP_ROOT/xcodebuild.log" 2>&1
XCODEBUILD_EXIT=$?
set -e

if [[ $XCODEBUILD_EXIT -ne 0 ]]; then
    echo "  ⚠️  xcodebuild exited with code $XCODEBUILD_EXIT — see $TEMP_ROOT/xcodebuild.log"
fi

for LANG_CODE in en de; do
    SHOTS=$(find "$TEMP_ROOT/$LANG_CODE" -maxdepth 1 -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$SHOTS" -gt 0 ]]; then
        cp "$TEMP_ROOT/$LANG_CODE"/*.png "$OUTPUT_ROOT/$LANG_CODE/"
        echo "  ✓ $SHOTS screenshot(s) saved to screenshots/$LANG_CODE/"
    else
        echo "  ✗ No screenshots produced for $LANG_CODE. Inspect $TEMP_ROOT/xcodebuild.log"
    fi
done

echo
echo "Done."
if command -v open >/dev/null 2>&1; then
    open "$OUTPUT_ROOT"
fi
