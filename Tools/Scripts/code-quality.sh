#!/bin/bash

# Code Quality Script for Xcode Cloud

# Exit on any error
set -e

# Navigate to project root
cd "$(dirname "$0")"/..

echo "Running code quality checks..."

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo "Error: SwiftLint is not installed"
    echo "Installing SwiftLint..."
    if command -v brew &> /dev/null; then
        brew install swiftlint
    else
        echo "Error: Homebrew is not installed. Cannot install SwiftLint automatically."
        exit 1
    fi
fi

# Check if SwiftFormat is installed
if ! command -v swiftformat &> /dev/null; then
    echo "Error: SwiftFormat is not installed"
    echo "Installing SwiftFormat..."
    if command -v brew &> /dev/null; then
        brew install swiftformat
    else
        echo "Error: Homebrew is not installed. Cannot install SwiftFormat automatically."
        exit 1
    fi
fi

# Run SwiftLint with strict mode (will fail on warnings)
echo "Running SwiftLint..."
swiftlint lint --strict

# Run SwiftFormat validation
echo "Running SwiftFormat validation..."
swiftformat . --lint

echo "Code quality checks passed!"