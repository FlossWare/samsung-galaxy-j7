#!/bin/bash
# Re-enable ALL disabled packages to fully restore the device
# Dynamically finds all disabled packages - always in sync with debloat

set -euo pipefail

# Check ADB connection first
if ! command -v adb &> /dev/null; then
    echo "❌ ERROR: ADB not found in PATH"
    exit 1
fi

if ! adb devices 2>/dev/null | grep -q "device$"; then
    echo "❌ ERROR: No Android device connected"
    exit 1
fi

echo "🔄 Finding all disabled packages..."
echo ""

DISABLED=$(adb shell pm list packages -d 2>/dev/null | cut -d: -f2 | tr -d '\r')
TOTAL=$(echo "$DISABLED" | grep -c . || true)

if [ "$TOTAL" -eq 0 ]; then
    echo "✅ No disabled packages found - nothing to restore."
    exit 0
fi

echo "Found $TOTAL disabled packages to restore."
echo ""

read -p "Re-enable all $TOTAL packages? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo ""
ENABLED=0
FAILED=0

for pkg in $DISABLED; do
    echo -n "  $pkg... "
    if adb shell pm enable "$pkg" 2>/dev/null | grep -q "enabled"; then
        echo "✓"
        ((ENABLED++))
    else
        echo "⚠ Failed"
        ((FAILED++))
    fi
done

echo ""
echo "✅ Package restore complete"
echo "   Enabled: $ENABLED"
echo "   Failed:  $FAILED"
echo ""
echo "Testing camera..."
adb shell am start -n com.sec.android.app.camera/.Camera
