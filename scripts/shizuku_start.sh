#!/bin/bash
# Start the Shizuku server on a Samsung J7 (Android 8.1, no root, no wireless debugging)
#
# Shizuku must be re-started after every reboot on Android < 11.
# The starter binary lives in the app's native lib dir, whose path changes on
# app updates - this script resolves it dynamically via the package manager.
#
# Usage: ./shizuku_start.sh [serial]

set -euo pipefail

SERIAL="${1:-}"
PKG="moe.shizuku.privileged.api"

adb_cmd() {
    if [ -n "$SERIAL" ]; then adb -s "$SERIAL" "$@"; else adb "$@"; fi
}

if ! adb_cmd devices 2>/dev/null | grep -q "device$"; then
    echo "❌ ERROR: No Android device connected"
    exit 1
fi

# Resolve the app's native library dir (contains libshizuku.so)
# Note: cut -f2- (not -f2) - the dir name ends in "==" which cut would eat,
# and the ABI subdir (e.g. "arm64") differs from ro.product.cpu.abi ("arm64-v8a"),
# so locate libshizuku.so by glob instead of guessing.
NATIVE_DIR=$(adb_cmd shell dumpsys package "$PKG" 2>/dev/null \
    | grep "legacyNativeLibraryDir=" | head -1 | cut -d= -f2- | tr -d '\r')

STARTER=$(adb_cmd shell "ls $NATIVE_DIR/*/libshizuku.so" 2>/dev/null | tr -d '\r' | head -1)

echo "Starting Shizuku server ($STARTER)..."
adb_cmd shell "$STARTER"

echo ""
sleep 3
if adb_cmd shell ps -A 2>/dev/null | grep -q "shizuku_server"; then
    echo "✅ Shizuku server is running"
else
    echo "❌ Server did not stay up - check the Shizuku app on the phone"
    exit 1
fi
