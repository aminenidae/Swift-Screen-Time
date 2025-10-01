#!/bin/bash

# Environment Verification Script

# Exit on any error
set -e

# Navigate to project root
cd "$(dirname "$0")"/..

echo "Verifying environment configuration..."

# Check if current environment configuration exists
if [ ! -f "Configuration/Current.plist" ]; then
    echo "Error: Current environment configuration not found"
    exit 1
fi

# Verify environment settings
ENVIRONMENT=$(plutil -extract Environment raw Configuration/Current.plist)
CLOUDKIT_CONTAINER=$(plutil -extract CloudKitContainer raw Configuration/Current.plist)
LOG_LEVEL=$(plutil -extract LogLevel raw Configuration/Current.plist)

echo "Current environment configuration:"
echo "  Environment: $ENVIRONMENT"
echo "  CloudKit Container: $CLOUDKIT_CONTAINER"
echo "  Log Level: $LOG_LEVEL"

# Verify feature flags
DEBUG_MODE=$(plutil -extract FeatureFlags.DebugMode raw Configuration/Current.plist)
MOCK_DATA=$(plutil -extract FeatureFlags.MockData raw Configuration/Current.plist)

echo "Feature flags:"
echo "  Debug Mode: $DEBUG_MODE"
echo "  Mock Data: $MOCK_DATA"

# Verify environment-specific behavior
case "$ENVIRONMENT" in
    "Development")
        if [ "$CLOUDKIT_CONTAINER" != "iCloud.com.screentimerewards.app.dev" ]; then
            echo "Error: Incorrect CloudKit container for Development environment"
            exit 1
        fi
        ;;
    "Staging")
        if [ "$CLOUDKIT_CONTAINER" != "iCloud.com.screentimerewards.app.staging" ]; then
            echo "Error: Incorrect CloudKit container for Staging environment"
            exit 1
        fi
        ;;
    "TestFlight"|"Production")
        if [ "$CLOUDKIT_CONTAINER" != "iCloud.com.screentimerewards.app" ]; then
            echo "Error: Incorrect CloudKit container for $ENVIRONMENT environment"
            exit 1
        fi
        ;;
    *)
        echo "Warning: Unknown environment: $ENVIRONMENT"
        ;;
esac

echo "Environment verification passed!"