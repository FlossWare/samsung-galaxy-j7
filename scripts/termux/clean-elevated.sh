#!/data/data/com.termux/files/usr/bin/bash
# Elevated cache clean - runs pm trim-caches with shell privileges via Shizuku/rish.
# Requires the Shizuku server to be running (scripts/shizuku_start.sh from laptop after reboot).
export RISH_APPLICATION_ID=com.termux
echo '--- free before ---'
df -k /data | tail -1
~/rish/rish -c 'pm trim-caches 999999999999 && echo TRIM-OK'
rm -rf /sdcard/.thumbnails/* 2>/dev/null
find /sdcard -name '*.tmp' -delete 2>/dev/null
echo '--- free after ---'
df -k /data | tail -1
