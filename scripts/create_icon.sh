#!/bin/bash
set -e

echo "🎨 Creating Momentum app icon..."

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "⚠️  ImageMagick not found. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Please install ImageMagick manually or install Homebrew first."
        echo "💡 Visit: https://brew.sh"
        exit 1
    fi
    brew install imagemagick
fi

# Create a temporary directory for icon files
ICON_DIR="icon_temp"
mkdir -p "$ICON_DIR"

# Generate a simple gradient icon with a flame/momentum symbol
# You can replace this with your own 1024x1024 PNG image
echo "📐 Generating base icon (1024x1024)..."

# Create a gradient background with a momentum symbol using ImageMagick
convert -size 1024x1024 \
    -define gradient:angle=135 \
    gradient:'#10b981-#06b6d4' \
    -gravity center \
    \( -size 512x512 xc:none -fill white \
       -draw "path 'M 256 50 L 350 250 L 450 150 L 400 350 L 500 450 L 256 500 L 12 450 L 112 350 L 62 150 L 162 250 Z'" \
    \) -composite \
    "$ICON_DIR/icon_1024x1024.png"

echo "✨ Creating icon set with all required sizes..."

# Standard sizes for macOS app icons
sizes=(16 32 64 128 256 512 1024)

for size in "${sizes[@]}"; do
    echo "  → ${size}x${size}"
    convert "$ICON_DIR/icon_1024x1024.png" -resize ${size}x${size} "$ICON_DIR/icon_${size}x${size}.png"
    
    # Create @2x versions for retina displays
    if [ $size -le 512 ]; then
        double=$((size * 2))
        convert "$ICON_DIR/icon_1024x1024.png" -resize ${double}x${double} "$ICON_DIR/icon_${size}x${size}@2x.png"
    fi
done

echo "📦 Creating .icns file..."

# Create iconset directory structure
ICONSET="$ICON_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"

# Copy files with proper naming for iconset
cp "$ICON_DIR/icon_16x16.png" "$ICONSET/icon_16x16.png"
cp "$ICON_DIR/icon_16x16@2x.png" "$ICONSET/icon_16x16@2x.png"
cp "$ICON_DIR/icon_32x32.png" "$ICONSET/icon_32x32.png"
cp "$ICON_DIR/icon_32x32@2x.png" "$ICONSET/icon_32x32@2x.png"
cp "$ICON_DIR/icon_128x128.png" "$ICONSET/icon_128x128.png"
cp "$ICON_DIR/icon_128x128@2x.png" "$ICONSET/icon_128x128@2x.png"
cp "$ICON_DIR/icon_256x256.png" "$ICONSET/icon_256x256.png"
cp "$ICON_DIR/icon_256x256@2x.png" "$ICONSET/icon_256x256@2x.png"
cp "$ICON_DIR/icon_512x512.png" "$ICONSET/icon_512x512.png"
cp "$ICON_DIR/icon_512x512@2x.png" "$ICONSET/icon_512x512@2x.png"

# Convert to .icns
iconutil -c icns "$ICONSET" -o AppIcon.icns

echo "🧹 Cleaning up temporary files..."
rm -rf "$ICON_DIR"

echo "✅ Icon created successfully!"
echo "📍 Icon file: AppIcon.icns"
echo ""
echo "🎯 Next steps:"
echo "   1. (Optional) Replace the generated icon with your custom design"
echo "   2. Run ./build_app.sh to rebuild the app with the new icon"

