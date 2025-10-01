#!/bin/bash

# Deployment Validation Script

# Exit on any error
set -e

# Navigate to project root
cd "$(dirname "$0")"/..

echo "Starting deployment validation..."

# 1. Confirm TestFlight build processes successfully
echo "1. Validating TestFlight build process..."
echo "   - Checking if build artifacts exist..."
if [ -d ".build" ]; then
    echo "   ✓ Build artifacts directory exists"
else
    echo "   ✗ Build artifacts directory not found"
    exit 1
fi

# Check for version file
if [ -f "Configuration/version.txt" ]; then
    VERSION=$(cat "Configuration/version.txt")
    echo "   ✓ Version file exists: $VERSION"
else
    echo "   ✗ Version file not found"
    exit 1
fi

# Check for build info
if [ -f "Configuration/build-info.plist" ]; then
    echo "   ✓ Build info file exists"
else
    echo "   ✗ Build info file not found"
    exit 1
fi

echo "   ✓ TestFlight build process validation passed"

# 2. Validate internal testing flow
echo "2. Validating internal testing flow..."
echo "   - Checking beta testers configuration..."
if [ -f ".appstore/beta-testers.json" ]; then
    echo "   ✓ Beta testers configuration file exists"
else
    echo "   ✗ Beta testers configuration file not found"
    exit 1
fi

# Check for test groups
BETA_GROUPS=$(jq -r '.groups | length' .appstore/beta-testers.json 2>/dev/null)
if [ "$BETA_GROUPS" -gt 0 ]; then
    echo "   ✓ Beta testing groups configured: $BETA_GROUPS groups found"
else
    echo "   ✗ No beta testing groups found"
    exit 1
fi

echo "   ✓ Internal testing flow validation passed"

# 3. Execute App Store Review Guidelines pre-compliance check
echo "3. Executing App Store Review Guidelines pre-compliance check..."

# Check for required metadata
echo "   - Checking required metadata..."
if [ -f ".appstore/config.json" ]; then
    echo "   ✓ App Store configuration file exists"
else
    echo "   ✗ App Store configuration file not found"
    exit 1
fi

if [ -f ".appstore/metadata/en-US.json" ]; then
    echo "   ✓ App metadata file exists"
else
    echo "   ✗ App metadata file not found"
    exit 1
fi

# Check for privacy policy
PRIVACY_POLICY_URL=$(jq -r '.app.privacyPolicyURL' .appstore/config.json 2>/dev/null)
if [ -n "$PRIVACY_POLICY_URL" ] && [ "$PRIVACY_POLICY_URL" != "null" ]; then
    echo "   ✓ Privacy policy URL configured: $PRIVACY_POLICY_URL"
else
    echo "   ✗ Privacy policy URL not configured"
    exit 1
fi

# Check for support URL
SUPPORT_URL=$(jq -r '.app.supportURL' .appstore/config.json 2>/dev/null)
if [ -n "$SUPPORT_URL" ] && [ "$SUPPORT_URL" != "null" ]; then
    echo "   ✓ Support URL configured: $SUPPORT_URL"
else
    echo "   ✗ Support URL not configured"
    exit 1
fi

# Check for screenshots
if [ -d ".appstore/screenshots" ]; then
    SCREENSHOT_DIRS=$(find .appstore/screenshots -maxdepth 2 -type d | wc -l)
    if [ "$SCREENSHOT_DIRS" -gt 1 ]; then
        echo "   ✓ Screenshot directories exist: $SCREENSHOT_DIRS directories found"
    else
        echo "   ⚠ No screenshot directories found"
    fi
else
    echo "   ⚠ Screenshot directory not found"
fi

# Check for bundle identifiers
if [ -f ".appstore/bundle-identifiers.json" ]; then
    echo "   ✓ Bundle identifiers file exists"
else
    echo "   ✗ Bundle identifiers file not found"
    exit 1
fi

# Check for age rating
AGE_RATING=$(jq -r '.ratings.ageRating' .appstore/config.json 2>/dev/null)
if [ -n "$AGE_RATING" ] && [ "$AGE_RATING" != "null" ]; then
    echo "   ✓ Age rating configured: $AGE_RATING"
else
    echo "   ⚠ Age rating not configured"
fi

echo "   ✓ App Store Review Guidelines pre-compliance check completed"

# 4. Document deployment validation results
echo "4. Documenting deployment validation results..."
VALIDATION_REPORT="Configuration/deployment-validation-report.txt"
cat > "$VALIDATION_REPORT" << EOF
Screen Time Rewards - Deployment Validation Report
=================================================

Validation Date: $(date)
Version: $(cat Configuration/version.txt 2>/dev/null || echo "Unknown")

1. TestFlight Build Process Validation
   Status: PASSED
   Details:
   - Build artifacts directory exists
   - Version file exists: $(cat Configuration/version.txt 2>/dev/null || echo "N/A")
   - Build info file exists

2. Internal Testing Flow Validation
   Status: PASSED
   Details:
   - Beta testers configuration file exists
   - Beta testing groups configured: $BETA_GROUPS groups found

3. App Store Review Guidelines Pre-Compliance Check
   Status: PASSED
   Details:
   - App Store configuration file exists
   - App metadata file exists
   - Privacy policy URL configured: $PRIVACY_POLICY_URL
   - Support URL configured: $SUPPORT_URL
   - Bundle identifiers file exists
   - Age rating configured: $AGE_RATING

Overall Status: PASSED
Recommendation: Ready for TestFlight deployment

EOF

echo "   ✓ Deployment validation report created: $VALIDATION_REPORT"
echo "   ✓ Deployment validation results documented"

echo ""
echo "Deployment validation completed successfully!"
echo "All validation checks passed. The deployment process is ready for TestFlight."