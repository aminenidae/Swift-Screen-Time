#!/bin/bash

# Script to create placeholder app icons for Screen Time Rewards
# This creates simple colored placeholder icons that need to be replaced with actual designs

ICON_DIR="/Users/ameen/Documents/ScreenTimeRewards-Workspace/Apps/ScreenTimeApp/ScreenTimeApp/Assets.xcassets/AppIcon.appiconset"

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "ImageMagick not found. Please install ImageMagick or manually create the following icon files:"
    echo "Required icon files in $ICON_DIR:"
    echo "- app-icon-20x20@1x.png (20x20)"
    echo "- app-icon-20x20@2x.png (40x40)"
    echo "- app-icon-20x20@3x.png (60x60)"
    echo "- app-icon-29x29@1x.png (29x29)"
    echo "- app-icon-29x29@2x.png (58x58)"
    echo "- app-icon-29x29@3x.png (87x87)"
    echo "- app-icon-40x40@1x.png (40x40)"
    echo "- app-icon-40x40@2x.png (80x80)"
    echo "- app-icon-40x40@3x.png (120x120)"
    echo "- app-icon-60x60@2x.png (120x120)"
    echo "- app-icon-60x60@3x.png (180x180)"
    echo "- app-icon-76x76@1x.png (76x76)"
    echo "- app-icon-76x76@2x.png (152x152)"
    echo "- app-icon-83.5x83.5@2x.png (167x167)"
    echo "- app-icon-1024x1024@1x.png (1024x1024)"
    echo ""
    echo "To install ImageMagick: brew install imagemagick"
    exit 1
fi

echo "Creating placeholder app icons..."

# Create icons with a simple design - blue background with white "SR" text
create_icon() {
    local size=$1
    local filename=$2
    local text_size=$((size / 4))

    convert -size ${size}x${size} xc:'#007AFF' \
        -gravity center \
        -fill white \
        -font Arial-Bold \
        -pointsize $text_size \
        -annotate +0+0 'SR' \
        "$ICON_DIR/$filename"
}

# iPhone icons
create_icon 40 "app-icon-20x20@2x.png"
create_icon 60 "app-icon-20x20@3x.png"
create_icon 58 "app-icon-29x29@2x.png"
create_icon 87 "app-icon-29x29@3x.png"
create_icon 80 "app-icon-40x40@2x.png"
create_icon 120 "app-icon-40x40@3x.png"
create_icon 120 "app-icon-60x60@2x.png"
create_icon 180 "app-icon-60x60@3x.png"

# iPad icons
create_icon 20 "app-icon-20x20@1x.png"
create_icon 29 "app-icon-29x29@1x.png"
create_icon 40 "app-icon-40x40@1x.png"
create_icon 76 "app-icon-76x76@1x.png"
create_icon 152 "app-icon-76x76@2x.png"
create_icon 167 "app-icon-83.5x83.5@2x.png"

# App Store icon
create_icon 1024 "app-icon-1024x1024@1x.png"

echo "Placeholder app icons created successfully!"
echo "⚠️  IMPORTANT: These are placeholder icons. Replace them with your actual app icon design before App Store submission."
echo "Icons created in: $ICON_DIR"