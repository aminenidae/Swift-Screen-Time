#!/bin/bash

# Environment Setup Script for Xcode Cloud

# Exit on any error
set -e

# Navigate to project root
cd "$(dirname "$0")"/..

echo "Setting up environment..."

# Determine environment based on Xcode Cloud environment variables or branch name
if [ -n "$CI_BRANCH" ]; then
    case "$CI_BRANCH" in
        "main"|"master")
            ENVIRONMENT="Production"
            ;;
        "develop"|"dev")
            ENVIRONMENT="Development"
            ;;
        "staging"|"stage")
            ENVIRONMENT="Staging"
            ;;
        *)
            ENVIRONMENT="Development"
            ;;
    esac
elif [ -n "$CI_PULL_REQUEST" ]; then
    ENVIRONMENT="Development"
else
    ENVIRONMENT="Development"
fi

echo "Environment: $ENVIRONMENT"

# Copy appropriate configuration file
CONFIG_FILE="Configuration/$ENVIRONMENT.plist"
if [ -f "$CONFIG_FILE" ]; then
    echo "Using configuration: $CONFIG_FILE"
    cp "$CONFIG_FILE" Configuration/Current.plist
else
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Set environment variables
export APP_ENVIRONMENT="$ENVIRONMENT"
export CLOUDKIT_CONTAINER=$(plutil -extract CloudKitContainer raw "$CONFIG_FILE")
export LOG_LEVEL=$(plutil -extract LogLevel raw "$CONFIG_FILE")

echo "Environment variables set:"
echo "  APP_ENVIRONMENT: $APP_ENVIRONMENT"
echo "  CLOUDKIT_CONTAINER: $CLOUDKIT_CONTAINER"
echo "  LOG_LEVEL: $LOG_LEVEL"

# Configure feature flags
if plutil -extract FeatureFlags.DebugMode raw "$CONFIG_FILE" | grep -q "true"; then
    export DEBUG_MODE="true"
else
    export DEBUG_MODE="false"
fi

if plutil -extract FeatureFlags.MockData raw "$CONFIG_FILE" | grep -q "true"; then
    export MOCK_DATA="true"
else
    export MOCK_DATA="false"
fi

echo "Feature flags:"
echo "  DEBUG_MODE: $DEBUG_MODE"
echo "  MOCK_DATA: $MOCK_DATA"

echo "Environment setup completed!"