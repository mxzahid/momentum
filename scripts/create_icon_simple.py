#!/usr/bin/env python3
"""
Simple script to create a Momentum app icon using only Python (PIL/Pillow)
"""
import os
import sys
import subprocess
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("⚠️  Pillow not found. Installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow"])
    from PIL import Image, ImageDraw, ImageFont

def create_gradient_icon():
    """Create a simple gradient icon with a flame/momentum symbol"""
    size = 1024
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img)
    
    # Create gradient background (teal to cyan)
    for y in range(size):
        # Interpolate between colors
        r = int(16 + (6 - 16) * (y / size))
        g = int(185 + (182 - 185) * (y / size))
        b = int(129 + (212 - 129) * (y / size))
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    
    # Draw a simple flame/momentum symbol
    # Flame shape (simplified triangular flame)
    flame_color = (255, 255, 255, 230)  # White with slight transparency
    
    # Main flame body
    flame_points = [
        (512, 200),   # top
        (350, 800),   # bottom left
        (512, 700),   # middle
        (674, 800),   # bottom right
    ]
    
    # Create an overlay for transparency
    overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    
    # Draw outer flame
    overlay_draw.polygon(flame_points, fill=flame_color, outline=(255, 255, 255, 255), width=8)
    
    # Draw inner flame (smaller, offset up)
    inner_flame = [
        (512, 300),
        (420, 700),
        (512, 600),
        (604, 700),
    ]
    overlay_draw.polygon(inner_flame, fill=(255, 255, 255, 180))
    
    # Composite the overlay onto the gradient background
    img_rgba = img.convert('RGBA')
    img_rgba = Image.alpha_composite(img_rgba, overlay)
    
    return img_rgba.convert('RGB')

def create_iconset():
    """Create all required icon sizes and .icns file"""
    print("🎨 Creating Momentum app icon...")
    
    # Create base icon
    print("📐 Generating base icon (1024x1024)...")
    base_icon = create_gradient_icon()
    
    # Create temporary directory
    icon_dir = Path("icon_temp")
    icon_dir.mkdir(exist_ok=True)
    
    iconset_dir = icon_dir / "AppIcon.iconset"
    iconset_dir.mkdir(exist_ok=True)
    
    # Required sizes for macOS
    sizes = [
        (16, "16x16"),
        (32, "16x16@2x"),
        (32, "32x32"),
        (64, "32x32@2x"),
        (128, "128x128"),
        (256, "128x128@2x"),
        (256, "256x256"),
        (512, "256x256@2x"),
        (512, "512x512"),
        (1024, "512x512@2x"),
    ]
    
    print("✨ Creating icon set with all required sizes...")
    for size, name in sizes:
        print(f"  → {name}")
        resized = base_icon.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(iconset_dir / f"icon_{name}.png")
    
    print("📦 Creating .icns file...")
    
    # Use iconutil to create .icns
    try:
        subprocess.run(
            ["iconutil", "-c", "icns", str(iconset_dir), "-o", "AppIcon.icns"],
            check=True
        )
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to create .icns file: {e}")
        return False
    
    print("🧹 Cleaning up temporary files...")
    import shutil
    shutil.rmtree(icon_dir)
    
    print("✅ Icon created successfully!")
    print("📍 Icon file: AppIcon.icns")
    print()
    print("🎯 Next steps:")
    print("   1. (Optional) Edit this script to customize the icon design")
    print("   2. Run ./build_app.sh to rebuild the app with the new icon")
    
    return True

if __name__ == "__main__":
    success = create_iconset()
    sys.exit(0 if success else 1)

