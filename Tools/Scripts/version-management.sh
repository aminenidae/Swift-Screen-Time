#!/bin/bash

# Version Management Script for Xcode Cloud

# Exit on any error
set -e

# Navigate to project root
cd "$(dirname "$0")"/..

echo "Managing build version..."

# Get current git commit count as build number
BUILD_NUMBER=$(git rev-list --count HEAD)
echo "Build number: $BUILD_NUMBER"

# Extract version from Package.swift
VERSION_LINE=$(grep "swift-tools-version:" Package.swift)
if [ -n "$VERSION_LINE" ]; then
    # Extract the version number from the swift-tools-version line
    # This is a simplified approach - in a real scenario, you might want to store
    # the app version separately from the Swift tools version
    VERSION="1.0.$BUILD_NUMBER"
    echo "App version: $VERSION"
else
    VERSION="1.0.$BUILD_NUMBER"
    echo "Using default version: $VERSION"
fi

# Create version file
VERSION_FILE="Configuration/version.txt"
echo "$VERSION" > "$VERSION_FILE"
echo "Version file created: $VERSION_FILE"

# Also create a build info file
BUILD_INFO_FILE="Configuration/build-info.plist"
cat > "$BUILD_INFO_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleShortVersionString</key>
	<string>$VERSION</string>
	<key>CFBundleVersion</key>
	<string>$BUILD_NUMBER</string>
	<key>BuildDate</key>
	<string>$(date)</string>
	<key>GitCommit</key>
	<string>$(git rev-parse HEAD)</string>
	<key>GitBranch</key>
	<string>$(git rev-parse --abbrev-ref HEAD)</string>
</dict>
</plist>
EOF

echo "Build info file created: $BUILD_INFO_FILE"
echo "Version management completed!"