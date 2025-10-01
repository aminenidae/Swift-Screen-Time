#!/bin/bash

# Script to process the provided image as app icon for Screen Time Rewards
# This script requires ImageMagick and the source image

SOURCE_IMAGE="/Users/ameen/Documents/ScreenTimeRewards-Workspace/Apps/ScreenTimeApp/app_icon_source.png"
ICON_DIR="/Users/ameen/Documents/ScreenTimeRewards-Workspace/Apps/ScreenTimeApp/ScreenTimeApp/Assets.xcassets/AppIcon.appiconset"

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install imagemagick
    else
        echo "❌ Homebrew not found. Please install ImageMagick manually:"
        echo "   - macOS: brew install imagemagick"
        echo "   - Alternative: Download from https://imagemagick.org/"
        exit 1
    fi
fi

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Source image not found at: $SOURCE_IMAGE"
    echo "Please ensure the PNG file is saved at this location."
    exit 1
fi

echo "🎨 Processing app icon from source image..."
echo "📁 Source: $SOURCE_IMAGE"
echo "📁 Output: $ICON_DIR"

# Function to create resized icon with proper formatting for iOS
create_ios_icon() {
    local size=$1
    local filename=$2

    echo "   Creating ${filename} (${size}x${size})"

    # Create icon with proper iOS formatting:
    # - Remove any transparency (iOS icons must be opaque)
    # - Ensure proper color space
    # - Apply slight sharpening for smaller sizes
    convert "$SOURCE_IMAGE" \
        -background white -alpha remove \
        -colorspace sRGB \
        -resize ${size}x${size}! \
        -unsharp 0x0.5+0.5+0.008 \
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
echo "🔄 Generating all required icon sizes..."

# iPhone icons
create_ios_icon 40 "app-icon-20x20@2x.png"
create_ios_icon 60 "app-icon-20x20@3x.png"
create_ios_icon 58 "app-icon-29x29@2x.png"
create_ios_icon 87 "app-icon-29x29@3x.png"
create_ios_icon 80 "app-icon-40x40@2x.png"
create_ios_icon 120 "app-icon-40x40@3x.png"
create_ios_icon 120 "app-icon-60x60@2x.png"
create_ios_icon 180 "app-icon-60x60@3x.png"

# iPad icons
create_ios_icon 20 "app-icon-20x20@1x.png"
create_ios_icon 29 "app-icon-29x29@1x.png"
create_ios_icon 40 "app-icon-40x40@1x.png"
create_ios_icon 76 "app-icon-76x76@1x.png"
create_ios_icon 152 "app-icon-76x76@2x.png"
create_ios_icon 167 "app-icon-83.5x83.5@2x.png"

# App Store icon (most important - high quality)
echo "   Creating app-icon-1024x1024@1x.png (1024x1024) - App Store version"
convert "$SOURCE_IMAGE" \
    -background white -alpha remove \
    -colorspace sRGB \
    -resize 1024x1024! \
    -quality 100 \
    "$ICON_DIR/app-icon-1024x1024@1x.png"

echo ""
echo "✅ App icon generation complete!"
echo ""
echo "📋 Generated icons for:"
echo "   • iPhone (all sizes)"
echo "   • iPad (all sizes)"
echo "   • App Store (1024x1024)"
echo ""
echo "⚠️  IMPORTANT NOTES:"
echo "   1. The current image appears to be a generic PNG file icon"
echo "   2. For App Store submission, consider creating a custom icon that:"
echo "      - Represents screen time/rewards/family themes"
echo "      - Is unique and recognizable"
echo "      - Follows Apple's design guidelines"
echo "   3. Test the icons in Xcode to ensure they look good at all sizes"
echo ""
echo "🔍 View the generated icons in: $ICON_DIR"