#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$PROJECT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/noxcode"
OUTPUT_APP="$BUILD_DIR/Textream.app"
DMG_PATH="$BUILD_DIR/Textream.dmg"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_APP/Contents/MacOS" "$OUTPUT_APP/Contents/Resources"

cd "$REPO_DIR"
swift build -c release --product Textream

BINARY="$REPO_DIR/.build/release/Textream"
cp "$BINARY" "$OUTPUT_APP/Contents/MacOS/Textream"

cat > "$OUTPUT_APP/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ATSApplicationFontsPath</key><string>.</string>
    <key>CFBundleExecutable</key><string>Textream</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIdentifier</key><string>dev.fka.textream</string>
    <key>CFBundleName</key><string>Textream</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.5.0</string>
    <key>CFBundleVersion</key><string>1.5.0</string>
    <key>LSMinimumSystemVersion</key><string>15.7</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Generate AppIcon.icns from PNGs
ICON_SRC="$PROJECT_DIR/Textream/Assets.xcassets/AppIcon.appiconset"
ICONSET="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
for f in icon_16x16 icon_16x16@2x icon_32x32 icon_32x32@2x icon_128x128 icon_128x128@2x icon_256x256 icon_256x256@2x icon_512x512 icon_512x512@2x; do
  [ -f "$ICON_SRC/$f.png" ] && cp "$ICON_SRC/$f.png" "$ICONSET/$f.png"
done
if command -v iconutil &>/dev/null; then
  iconutil -c icns "$ICONSET" -o "$OUTPUT_APP/Contents/Resources/AppIcon.icns"
elif command -v sips &>/dev/null; then
  sips -s format icns "$ICON_SRC/icon_512x512@2x.png" --out "$OUTPUT_APP/Contents/Resources/AppIcon.icns" 2>/dev/null || true
fi

# Copy fonts
[ -d "$PROJECT_DIR/Textream/Fonts" ] && cp -R "$PROJECT_DIR/Textream/Fonts/" "$OUTPUT_APP/Contents/Resources/"

# Ad-hoc sign & DMG
codesign --force --deep --sign - "$OUTPUT_APP" 2>/dev/null || true
DMG_STAGING="$BUILD_DIR/dmg_staging"
rm -rf "$DMG_STAGING" && mkdir -p "$DMG_STAGING"
cp -R "$OUTPUT_APP" "$DMG_STAGING/" && ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "Textream" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_PATH" -quiet
rm -rf "$DMG_STAGING" "$ICONSET"

echo "Done: $DMG_PATH"
