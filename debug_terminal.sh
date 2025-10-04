#!/bin/bash

# Debug script to check terminal functionality
echo "=== Terminal Debug Information ==="
echo "Current directory: $(pwd)"
echo "User: $(whoami)"
echo "Shell: $SHELL"
echo "Date: $(date)"
echo ""
echo "=== Directory Contents ==="
ls -la
echo ""
echo "=== Xcode Availability ==="
if command -v xcodebuild &> /dev/null; then
    echo "✅ xcodebuild is available"
    xcodebuild -version
else
    echo "❌ xcodebuild is not available"
fi
echo ""
if command -v xcode-select &> /dev/null; then
    echo "Xcode path: $(xcode-select -p)"
else
    echo "xcode-select not available"
fi
echo ""
echo "=== Swift Availability ==="
if command -v swift &> /dev/null; then
    echo "✅ Swift is available"
    swift --version
else
    echo "❌ Swift is not available"
fi
echo ""
echo "=== File Verification ==="
if [ -f "ScreenTimeRewards.xcworkspace/contents.xcworkspacedata" ]; then
    echo "✅ Workspace file exists"
else
    echo "❌ Workspace file not found"
fi
echo ""
echo "=== Build Script Status ==="
if [ -f "build_debug.sh" ]; then
    echo "✅ Build script exists"
    echo "Build script permissions: $(ls -l build_debug.sh)"
else
    echo "❌ Build script not found"
fi
echo ""
if [ -f "verify_build.sh" ]; then
    echo "✅ Verification script exists"
    echo "Verification script permissions: $(ls -l verify_build.sh)"
else
    echo "❌ Verification script not found"
fi
echo ""
echo "=== Settings Implementation Files ==="
SETTINGS_DIR="Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings"
if [ -d "$SETTINGS_DIR" ]; then
    echo "✅ Settings directory exists"
    echo "Settings files:"
    ls -la "$SETTINGS_DIR"
else
    echo "❌ Settings directory not found"
fi