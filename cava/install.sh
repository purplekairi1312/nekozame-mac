#!/bin/bash
# builds nekozame-cava as a tiny app in ~/Applications (macOS asks once, by name,
# before it can hear what's playing) and starts it at login
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Applications/nekozame-cava.app"
mkdir -p "$APP/Contents/MacOS"
swiftc -O -suppress-warnings -o "$APP/Contents/MacOS/nekozame-cava" "$HERE/main.swift"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.nekozame.cava</string>
  <key>CFBundleName</key><string>nekozame-cava</string>
  <key>CFBundleExecutable</key><string>nekozame-cava</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
  <key>NSAudioCaptureUsageDescription</key><string>To draw cava's bars on the bar from what's playing. It only reads a copy: your audio isn't changed.</string>
</dict></plist>
PLIST
codesign -s - --force "$APP" 2>/dev/null
AGENT="$HOME/Library/LaunchAgents/com.nekozame.cava.plist"
cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.nekozame.cava</string>
  <key>ProgramArguments</key><array><string>$APP/Contents/MacOS/nekozame-cava</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>10</integer>
</dict></plist>
PLIST
launchctl bootout "gui/$(id -u)/com.nekozame.cava" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENT"
