#!/bin/bash

# Build and Test Script for Xcode Cloud

# Exit on any error
set -e

# Navigate to project root
cd "$(dirname "$0")"/..

# Verify environment configuration
echo "Verifying environment configuration..."
if [ -f "Scripts/verify-environment.sh" ]; then
    Scripts/verify-environment.sh
else
    echo "Environment verification script not found, skipping..."
fi

# Run SwiftLint
echo "Running SwiftLint..."
if command -v swiftlint &> /dev/null; then
    swiftlint lint --strict
else
    echo "SwiftLint not found, skipping..."
fi

# Run SwiftFormat
echo "Running SwiftFormat..."
if command -v swiftformat &> /dev/null; then
    swiftformat . --lint
else
    echo "SwiftFormat not found, skipping..."
fi

# Run tests with coverage
echo "Running tests with coverage..."
swift test --enable-code-coverage

# Generate coverage report
echo "Generating coverage report..."
if command -v xccov &> /dev/null; then
    # Find the latest coverage archive
    coverage_file=$(find .build -name "*.xccovarchive" | head -n 1)
    if [ -n "$coverage_file" ]; then
        xccov view --report "$coverage_file" > coverage-report.json
        echo "Coverage report generated: coverage-report.json"
    else
        echo "No coverage archive found"
    fi
else
    echo "xccov not found, skipping coverage report generation..."
fi

echo "Build and test completed successfully!"