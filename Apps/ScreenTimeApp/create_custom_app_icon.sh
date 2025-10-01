#!/bin/bash

# Script to create a custom app icon for Screen Time Rewards
# This creates an icon with clock, star, and family-friendly design

ICON_DIR="/Users/ameen/Documents/ScreenTimeRewards-Workspace/Apps/ScreenTimeApp/ScreenTimeApp/Assets.xcassets/AppIcon.appiconset"

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick not found. Please install it first:"
    echo "   brew install imagemagick"
    echo ""
    echo "Or download from: https://imagemagick.org/"
    exit 1
fi

echo "🎨 Creating custom Screen Time Rewards app icon..."

# Function to create custom Screen Time Rewards icon
create_custom_icon() {
    local size=$1
    local filename=$2
    local clock_size=$((size / 3))
    local star_size=$((size / 5))
    local font_size=$((size / 8))

    echo "   Creating ${filename} (${size}x${size})"

    # Create a gradient background from blue to light blue
    convert -size ${size}x${size} \
        gradient:'#007AFF-#87CEEB' \
        \( -size ${clock_size}x${clock_size} xc:white \
           -fill '#333333' \
           -stroke '#333333' \
           -strokewidth 2 \
           -draw "circle $((clock_size/2)),$((clock_size/2)) $((clock_size/2)),$((clock_size/4))" \
           -draw "line $((clock_size/2)),$((clock_size/2)) $((clock_size/2)),$((clock_size/4))" \
           -draw "line $((clock_size/2)),$((clock_size/2)) $((clock_size*3/4)),$((clock_size/2))" \
        \) \
        -gravity center \
        -geometry +0-$((size/6)) \
        -composite \
        \( -size ${star_size}x${star_size} xc:transparent \
           -fill '#FFD700' \
           -stroke '#FFA500' \
           -strokewidth 1 \
           -draw "path 'M $((star_size/2)),2 L $((star_size*3/5)),$((star_size*2/5)) L $((star_size-2)),$((star_size*2/5)) L $((star_size*7/10)),$((star_size*3/5)) L $((star_size*4/5)),$((star_size-2)) L $((star_size/2)),$((star_size*7/10)) L $((star_size/5)),$((star_size-2)) L $((star_size*3/10)),$((star_size*3/5)) L 2,$((star_size*2/5)) L $((star_size*2/5)),$((star_size*2/5)) Z'" \
        \) \
        -gravity southeast \
        -geometry +$((size/8))+$((size/8)) \
        -composite \
        -quality 100 \
        "$ICON_DIR/$filename"

    if [ $? -eq 0 ]; then
        echo "   ✅ Created $filename"
    else
        echo "   ❌ Failed to create $filename"
    fi
}

# Create the icons directory if it doesn't exist
mkdir -p "$ICON_DIR"

echo ""
echo "🔄 Generating custom Screen Time Rewards icons..."

# iPhone icons
create_custom_icon 40 "app-icon-20x20@2x.png"
create_custom_icon 60 "app-icon-20x20@3x.png"
create_custom_icon 58 "app-icon-29x29@2x.png"
create_custom_icon 87 "app-icon-29x29@3x.png"
create_custom_icon 80 "app-icon-40x40@2x.png"
create_custom_icon 120 "app-icon-40x40@3x.png"
create_custom_icon 120 "app-icon-60x60@2x.png"
create_custom_icon 180 "app-icon-60x60@3x.png"

# iPad icons
create_custom_icon 20 "app-icon-20x20@1x.png"
create_custom_icon 29 "app-icon-29x29@1x.png"
create_custom_icon 40 "app-icon-40x40@1x.png"
create_custom_icon 76 "app-icon-76x76@1x.png"
create_custom_icon 152 "app-icon-76x76@2x.png"
create_custom_icon 167 "app-icon-83.5x83.5@2x.png"

# App Store icon
create_custom_icon 1024 "app-icon-1024x1024@1x.png"

echo ""
echo "✅ Custom Screen Time Rewards app icon created!"
echo ""
echo "🎨 Icon Design Features:"
echo "   • Blue gradient background (trustworthy, family-friendly)"
echo "   • Clock symbol (represents time management)"
echo "   • Gold star (represents rewards/achievements)"
echo "   • Clean, modern design"
echo ""
echo "📁 Icons saved to: $ICON_DIR"
echo ""
echo "🔍 Next steps:"
echo "   1. Open Xcode and verify the icons appear correctly"
echo "   2. Build the project to test icon integration"
echo "   3. Consider refining the design with a professional designer"