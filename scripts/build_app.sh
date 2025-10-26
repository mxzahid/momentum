#!/bin/bash
set -e

echo "🔨 Building Momentum.app bundle..."

# Build the release binary
echo "📦 Building release binary..."
swift build -c release

# Create app bundle structure
APP_NAME="Momentum"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📁 Creating app bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy the executable
echo "📋 Copying executable..."
cp ".build/arm64-apple-macosx/release/$APP_NAME" "$MACOS_DIR/"
chmod +x "$MACOS_DIR/$APP_NAME"

# Copy entitlements
echo "🔐 Copying entitlements..."
cp "Momentum.entitlements" "$RESOURCES_DIR/"

# Copy icon if it exists
if [ -f "AppIcon.icns" ]; then
    echo "🎨 Copying app icon..."
    cp "AppIcon.icns" "$RESOURCES_DIR/"
fi

# Create Info.plist
echo "📝 Creating Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.momentum.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# Code sign the app (ad-hoc signature)
echo "✍️  Signing app..."
codesign --force --deep --sign - --entitlements "Momentum.entitlements" "$APP_BUNDLE"

echo "✅ Build complete!"
echo "📍 App bundle created at: $APP_BUNDLE"
echo ""
echo "🚀 To run the app:"
echo "   open $APP_BUNDLE"
echo ""
echo "📦 To install to Applications:"
echo "   cp -r $APP_BUNDLE /Applications/"

