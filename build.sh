#!/bin/sh
# Builds build/Ice.app and signs it ad hoc with the sandbox entitlements.
# Needs only the Xcode Command Line Tools.
set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/build/Ice.app"

swift build -c release --package-path "$ROOT" -Xswiftc -Osize
BIN="$(swift build -c release --package-path "$ROOT" --show-bin-path)/Ice"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Ice"
strip -x "$APP/Contents/MacOS/Ice"
cp "$ROOT/Support/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Support/AppIcon.icns" "$ROOT/Support/IceCubeFill.png" "$ROOT/Support/IceCubeStroke.png" \
    "$APP/Contents/Resources/"

codesign --force --sign - --options runtime --entitlements "$ROOT/Support/Ice.entitlements" "$APP"
echo "Built $APP"
