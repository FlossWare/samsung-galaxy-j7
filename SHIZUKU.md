# Shizuku Setup (Elevated Commands Without Root)

**Last tested:** 2026-11-20 with android-j7-01 (SM-J727V, Android 8.1), Shizuku v13.6.0

---

## Why

Android apps cannot clear other apps' caches, run `pm trim-caches`, or most other
privileged operations — those powers belong to the `shell` user (uid 2000), reachable
normally only via adb from a laptop or by rooting the phone.

[Shizuku](https://shizuku.rikka.app/) runs a small server **as the shell user**
(spawned once via adb) that other apps and terminals can then ask to run commands
on their behalf — with per-app user approval. `rish` (Remote Interactive SHell)
is the command-line client: it lets Termux run commands with those shell
privileges, no laptop in the loop.

**The one catch on Android < 11:** the Shizuku server dies on reboot and must be
re-started via adb from a laptop (`scripts/shizuku_start.sh`). On Android 11+
devices the server can start itself via wireless debugging — no laptop needed.

---

## One-Time Setup

### 1. Install Shizuku

Download the release APK from https://github.com/RikkaApps/Shizuku/releases
and install it:

```bash
adb install shizuku-v*.apk
```

### 2. Start the server (after every reboot on Android < 11)

```bash
./scripts/shizuku_start.sh [serial]
```

The script resolves the app's native library directory and runs the starter
binary as the shell user. Shizuku v13+ no longer uses the old
`/sdcard/Android/data/.../start.sh` mechanism.

To start manually:

```bash
adb shell "$(adb shell dumpsys package moe.shizuku.privileged.api | \
  grep legacyNativeLibraryDir | cut -d= -f2-)/arm64/libshizuku.so"
```

### 3. Install rish into Termux

Extract the three rish files from the Shizuku APK and copy them to Termux
(`~/rish/`):

```bash
# On the laptop, with the Shizuku APK downloaded:
unzip shizuku-v*.apk assets/rish assets/rish_shizuku.dex lib/arm64-v8a/librish.so -d rish-extract
scp -P 8022 -i ~/.ssh/id_rsa \
  rish-extract/assets/rish \
  rish-extract/assets/rish_shizuku.dex \
  rish-extract/lib/arm64-v8a/librish.so \
  u0_a186@<phone-ip>:rish/
```

### 4. Authorize Termux (one time only)

On Android 8.0/8.1 the permission request broadcast is broken, so the request
must come from a **foreground** Termux session. In the Termux app (on the phone
screen) run:

```bash
export RISH_APPLICATION_ID=com.termux
~/rish/rish -c id
```

A dialog "Allow Termux to access Shizuku?" appears — choose **Allow all the
time**. (The first request may time out before you tap; run the command again.)

After this one-time grant, `rish` works from background contexts (SSH, cron,
scripts) with no screen interaction.

### 5. Use it

```bash
export RISH_APPLICATION_ID=com.termux
~/rish/rish -c 'pm trim-caches 999999999999'   # elevated!
~/rish/rish -c 'id'                            # -> uid=2000(shell)
```

`scripts/termux/clean-elevated.sh` (deployed to the Termux home directory)
wraps the elevated cache clean for use on the phone.

---

## Files

| Location | Purpose |
|---|---|
| `scripts/shizuku_start.sh` (laptop) | Start the Shizuku server via adb |
| `~/rish/` (Termux) | rish + dex + native lib, extracted from the Shizuku APK |
| `~/clean-elevated.sh` (Termux) | Elevated cache clean via rish |

## Troubleshooting

- **"root permission not granted" in the Shizuku app** — the in-app Start
  button tries root/wireless-debugging; on Android < 11 use the adb route.
- **"Request timeout" from rish** — on 8.0/8.1 run rish once from the
  foreground Termux app so the permission dialog can appear (see step 4).
- **After reboot nothing works** — the server died; re-run
  `scripts/shizuku_start.sh` from the laptop.
