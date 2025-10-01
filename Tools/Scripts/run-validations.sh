#!/bin/bash

# Run All Validations Script

# Exit on any error
set -e

# Navigate to project root
cd "$(dirname "$0")"/..

echo "Running all validation checks..."

# Run deployment validation
echo "1. Running deployment validation..."
if [ -f "Scripts/deployment-validation.sh" ]; then
    Scripts/deployment-validation.sh
else
    echo "Error: Deployment validation script not found"
    exit 1
fi

# Run code quality validation
echo "2. Running code quality validation..."
if [ -f "Scripts/code-quality.sh" ]; then
    Scripts/code-quality.sh
else
    echo "Warning: Code quality validation script not found"
fi

# Run environment validation
echo "3. Running environment validation..."
if [ -f "Scripts/verify-environment.sh" ]; then
    Scripts/verify-environment.sh
else
    echo "Warning: Environment validation script not found"
fi

echo ""
echo "All validation checks completed!"