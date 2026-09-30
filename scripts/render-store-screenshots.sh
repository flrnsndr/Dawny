#!/usr/bin/env bash
#
# Turns the raw captures in screenshots/<lang>/ into the captioned App Store
# screenshots (1320 × 2868, iPhone 6.9") for English and German.
#
# Layout lives in scripts/store-screenshots/template.html, the texts in
# scripts/store-screenshots/captions.js. Each image is one headless Chrome
# render of the template.
#
# Run ./scripts/take-screenshots.sh first (and take 04_Widgets.png by hand),
# then:
#
#   ./scripts/render-store-screenshots.sh
#
# Output:
#   screenshots/store/<lang>/0{1..6}_*.png
#
# Requires: Google Chrome (override the binary with CHROME=...).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
TEMPLATE="$PROJECT_ROOT/scripts/store-screenshots/template.html"
OUTPUT_ROOT="$PROJECT_ROOT/screenshots/store"

SLIDES=(reset backlog today archive widgets free)
NAMES=(01_Reset 02_Backlog 03_Today 04_Archive 05_Widgets 06_Free)
RAW=(01_Backlog 02_Today 03_Archive 04_Widgets 05_TodayMorning)

if [[ ! -x "$CHROME" ]]; then
    echo "✗ Chrome not found at $CHROME (set CHROME=...)" >&2
    exit 1
fi

for LANG_CODE in en de; do
    for RAW_NAME in "${RAW[@]}"; do
        if [[ ! -f "screenshots/$LANG_CODE/$RAW_NAME.png" ]]; then
            echo "✗ Missing screenshots/$LANG_CODE/$RAW_NAME.png" >&2
            exit 1
        fi
    done

    mkdir -p "$OUTPUT_ROOT/$LANG_CODE"
    for i in "${!SLIDES[@]}"; do
        OUT="$OUTPUT_ROOT/$LANG_CODE/${NAMES[$i]}.png"
        "$CHROME" --headless=new --disable-gpu --hide-scrollbars \
            --force-device-scale-factor=1 --window-size=1320,2868 \
            --virtual-time-budget=4000 --allow-file-access-from-files \
            --screenshot="$OUT" \
            "file://$TEMPLATE?lang=$LANG_CODE&slide=${SLIDES[$i]}" > /dev/null 2>&1
        echo "  ✓ $LANG_CODE/${NAMES[$i]}.png"
    done
done

echo
echo "Done. Upload screenshots/store/<lang>/ in App Store Connect (6.9\" display)."
