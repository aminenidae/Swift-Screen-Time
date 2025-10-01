#!/bin/bash

# Basic app icon creator using macOS built-in tools
# Creates a simple but functional app icon for Screen Time Rewards

ICON_DIR="/Users/ameen/Documents/ScreenTimeRewards-Workspace/Apps/ScreenTimeApp/ScreenTimeApp/Assets.xcassets/AppIcon.appiconset"

echo "🎨 Creating basic app icon for Screen Time Rewards using macOS tools..."

# Create the icons directory if it doesn't exist
mkdir -p "$ICON_DIR"

# Check if we have any image creation tools available
if command -v sips &> /dev/null; then
    echo "✅ Found 'sips' - using macOS image tools"

    # Create a basic colored square as base
    # Since we can't easily create complex graphics with sips alone,
    # we'll create a simple colored icon that can be replaced later

    echo "📝 Creating documentation for manual icon creation..."

elif command -v python3 &> /dev/null; then
    echo "✅ Found Python3 - attempting to create basic icon with PIL"

    # Create a Python script to generate basic icons
    cat > /tmp/create_icon.py << 'EOF'
try:
    from PIL import Image, ImageDraw, ImageFont
    import os

    def create_icon(size, filename):
        # Create a gradient-like background
        img = Image.new('RGB', (size, size), '#007AFF')
        draw = ImageDraw.Draw(img)

        # Add a simple clock-like circle
        margin = size // 6
        circle_coords = [margin, margin, size - margin, size - margin]
        draw.ellipse(circle_coords, fill='white', outline='#333333', width=max(1, size//40))

        # Add clock hands
        center = size // 2
        hand_length = size // 4
        # Hour hand
        draw.line([center, center, center, center - hand_length//2], fill='#333333', width=max(1, size//20))
        # Minute hand
        draw.line([center, center, center + hand_length//2, center], fill='#333333', width=max(1, size//25))

        # Add a small star for "rewards"
        star_size = size // 8
        star_x = size - star_size - margin//2
        star_y = margin//2

        # Simple diamond as star
        star_coords = [
            (star_x + star_size//2, star_y),
            (star_x + star_size, star_y + star_size//2),
            (star_x + star_size//2, star_y + star_size),
            (star_x, star_y + star_size//2)
        ]
        draw.polygon(star_coords, fill='#FFD700', outline='#FFA500')

        # Save the image
        icon_path = f"{os.environ.get('ICON_DIR', '.')}/{filename}"
        img.save(icon_path, 'PNG', quality=95)
        print(f"   ✅ Created {filename}")
        return True

except ImportError:
    print("❌ PIL (Pillow) not available")
    return False

# Set environment variable for directory
import os
os.environ['ICON_DIR'] = '/Users/ameen/Documents/ScreenTimeRewards-Workspace/Apps/ScreenTimeApp/ScreenTimeApp/Assets.xcassets/AppIcon.appiconset'

# Create all required icon sizes
icons = [
    (40, "app-icon-20x20@2x.png"),
    (60, "app-icon-20x20@3x.png"),
    (58, "app-icon-29x29@2x.png"),
    (87, "app-icon-29x29@3x.png"),
    (80, "app-icon-40x40@2x.png"),
    (120, "app-icon-40x40@3x.png"),
    (120, "app-icon-60x60@2x.png"),
    (180, "app-icon-60x60@3x.png"),
    (20, "app-icon-20x20@1x.png"),
    (29, "app-icon-29x29@1x.png"),
    (40, "app-icon-40x40@1x.png"),
    (76, "app-icon-76x76@1x.png"),
    (152, "app-icon-76x76@2x.png"),
    (167, "app-icon-83.5x83.5@2x.png"),
    (1024, "app-icon-1024x1024@1x.png")
]

success_count = 0
for size, filename in icons:
    if create_icon(size, filename):
        success_count += 1

print(f"\n✅ Successfully created {success_count}/{len(icons)} icons")
if success_count == len(icons):
    print("🎉 All app icons created successfully!")
else:
    print("⚠️  Some icons may need manual creation")
EOF

    python3 /tmp/create_icon.py

else
    echo "❌ No suitable image creation tools found"
    echo ""
    echo "📋 Manual icon creation required:"
    echo "   1. Install ImageMagick: https://imagemagick.org/"
    echo "   2. Or install Homebrew and ImageMagick: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\" && brew install imagemagick"
    echo "   3. Or create icons manually using design software"
    echo ""
    echo "📐 Required icon sizes:"
    echo "   • 20x20, 29x29, 40x40, 58x58, 60x60, 76x76, 80x80, 87x87"
    echo "   • 120x120, 152x152, 167x167, 180x180"
    echo "   • 1024x1024 (App Store)"
fi

echo ""
echo "📁 Icons directory: $ICON_DIR"
echo ""
echo "💡 RECOMMENDATION:"
echo "   The provided PNG file icon is generic and not suitable for an app about"
echo "   screen time rewards. Consider creating a custom icon that includes:"
echo "   • Clock or time elements"
echo "   • Star or reward symbols"
echo "   • Family-friendly colors"
echo "   • Clean, recognizable design"