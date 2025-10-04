#!/bin/bash

# Build script for ScreenTime Rewards app
echo "Building ScreenTime Rewards for debugging..."

# Navigate to the project directory
cd "$(dirname "$0")"

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ScreenTimeApp*

# Build the project
echo "Building project..."
xcodebuild -workspace ScreenTimeRewards.xcworkspace \
  -scheme ScreenTimeApp \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  clean build \
  -quiet

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "To run the app in simulator:"
    echo "  1. Open Xcode"
    echo "  2. Select the ScreenTimeApp scheme"
    echo "  3. Choose iOS Simulator as target"
    echo "  4. Run the project"
else
    echo "Build failed. Check the error messages above."
fi