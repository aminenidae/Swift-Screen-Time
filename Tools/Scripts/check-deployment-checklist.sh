#!/bin/bash

# Deployment Checklist Validation Script

# Exit on any error
set -e

# Navigate to project root
cd "$(dirname "$0")"/..

echo "Validating deployment checklist..."

# Initialize counters
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Function to check if a file exists
check_file_exists() {
    local file_path="$1"
    local description="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -f "$file_path" ]; then
        echo "✓ $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo "✗ $description (MISSING)"
        return 1
    fi
}

# Function to check if a directory exists
check_dir_exists() {
    local dir_path="$1"
    local description="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -d "$dir_path" ]; then
        echo "✓ $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo "✗ $description (MISSING)"
        return 1
    fi
}

# Function to check JSON field
check_json_field() {
    local file_path="$1"
    local field_path="$2"
    local description="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -f "$file_path" ]; then
        local value=$(jq -r "$field_path" "$file_path" 2>/dev/null)
        if [ -n "$value" ] && [ "$value" != "null" ] && [ "$value" != "" ]; then
            echo "✓ $description"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            return 0
        else
            echo "✗ $description (NOT SET)"
            return 1
        fi
    else
        echo "✗ $description (FILE MISSING)"
        return 1
    fi
}

echo ""
echo "TestFlight Build Process Validation:"
echo "===================================="

check_dir_exists ".build" "Build artifacts directory exists"
check_file_exists "Configuration/version.txt" "Version file exists"
check_file_exists "Configuration/build-info.plist" "Build info file exists"
check_file_exists "Configuration/release-notes.txt" "Release notes file exists"

echo ""
echo "Internal Testing Flow Validation:"
echo "================================="

check_file_exists ".appstore/beta-testers.json" "Beta testers configuration file exists"
check_dir_exists ".appstore" "App Store configuration directory exists"

echo ""
echo "App Store Review Guidelines Pre-Compliance Check:"
echo "================================================="

check_file_exists ".appstore/config.json" "App Store configuration file exists"
check_file_exists ".appstore/metadata/en-US.json" "App metadata file exists"
check_json_field ".appstore/config.json" ".app.privacyPolicyURL" "Privacy policy URL is configured"
check_json_field ".appstore/config.json" ".app.supportURL" "Support URL is configured"
check_file_exists ".appstore/bundle-identifiers.json" "Bundle identifiers file exists"
check_json_field ".appstore/config.json" ".ratings.ageRating" "Age rating is configured"

echo ""
echo "Technical Validation:"
echo "===================="

check_file_exists "Configuration/Development.plist" "Development environment configuration exists"
check_file_exists "Configuration/Production.plist" "Production environment configuration exists"
check_file_exists "Configuration/Staging.plist" "Staging environment configuration exists"
check_file_exists "Configuration/TestFlight.plist" "TestFlight environment configuration exists"

echo ""
echo "Documentation Validation:"
echo "========================"

check_file_exists "README.md" "README.md exists"
check_dir_exists "Docs" "Documentation directory exists"

echo ""
echo "Validation Summary:"
echo "==================="

echo "Total checks: $TOTAL_CHECKS"
echo "Passed checks: $PASSED_CHECKS"
echo "Failed checks: $((TOTAL_CHECKS - PASSED_CHECKS))"

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo ""
    echo "🎉 All deployment checklist items passed!"
    echo "✅ Deployment is ready for TestFlight."
    exit 0
else
    echo ""
    echo "⚠️  Some deployment checklist items failed."
    echo "❌ Please address the failed items before deployment."
    exit 1
fi