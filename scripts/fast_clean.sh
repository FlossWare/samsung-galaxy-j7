#!/bin/bash
# Fast storage cleaner - adb replacement for "1 Tap Cleaner" class apps
# Runtime: ~10 seconds (vs 3-5 minutes for clear_all_caches.sh)
#
# What it does:
#   1. pm trim-caches  - one-shot system call that frees ALL reclaimable app
#                        cache (same mechanism Android Storage Manager uses
#                        when storage runs low). Replaces the slow per-app
#                        `pm clear --cache-only` loop entirely.
#   2. logcat -c       - clear the in-memory log buffer
#   3. thumbnail/tmp   - remove regenerable files in shared storage
#
# What it does NOT touch (by design):
#   - App data (logins, settings, game saves, OTP seeds)
#   - Anything in the per-app SKIP list semantics of clear_all_caches.sh -
#     trim-caches only frees true cache files the system marks reclaimable,
#     so protected apps (Authy, FreeOTP, Nova, etc.) keep their state.
#
# Usage:
#   ./fast_clean.sh [serial]     # optional adb serial if multiple phones

set -euo pipefail

SERIAL="${1:-}"

adb_cmd() {
    if [ -n "$SERIAL" ]; then
        adb -s "$SERIAL" "$@"
    else
        adb "$@"
    fi
}

# Verify connection
if ! adb_cmd devices 2>/dev/null | grep -q "device$"; then
    echo "❌ ERROR: No Android device connected"
    exit 1
fi

free_kb() {
    adb_cmd shell dumpsys diskstats 2>/dev/null | grep "Data-Free:" | awk '{print $2}' | sed 's/K//' | tr -d '\r'
}

BEFORE_KB=$(free_kb)

echo "🧹 Fast Clean"
echo "=========================================="
echo "📊 Free space before: $((BEFORE_KB / 1024))MB"
echo ""

echo -n "  Trimming all app caches (system-wide)... "
adb_cmd shell pm trim-caches 999999999999
echo "✓"

echo -n "  Clearing log buffer... "
adb_cmd logcat -c 2>/dev/null || true
echo "✓"

echo -n "  Removing thumbnails and temp files... "
adb_cmd shell "rm -rf /sdcard/.thumbnails/* 2>/dev/null; find /sdcard -name '*.tmp' -delete 2>/dev/null"
echo "✓"

AFTER_KB=$(free_kb)
FREED_MB=$(( (AFTER_KB - BEFORE_KB) / 1024 ))

echo ""
echo "=========================================="
echo "✅ Done in seconds"
echo "📊 Free space after:  $((AFTER_KB / 1024))MB"
echo "💾 Freed:             ${FREED_MB}MB"
echo ""
echo "💡 If storage is still tight, the space is in app DATA (not cache)."
echo "   Check big consumers with:"
echo "   adb shell dumpsys diskstats"
echo ""
