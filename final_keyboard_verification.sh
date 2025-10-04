#!/bin/bash

# Final verification script for keyboard type fixes
echo "=== Final Keyboard Type Verification ==="

# Check that the correct keyboardType values are used
if grep -q "keyboardType(isInteger ? .numberPad : .decimalPad)" "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/NumericSettingView.swift"; then
    echo "✅ Correct keyboardType usage found: .numberPad and .decimalPad"
else
    echo "❌ Correct keyboardType usage not found"
    exit 1
fi

# Check that there are no remaining incorrect .number references in Swift files
if grep -r "\.number\b" "Apps/ScreenTimeApp/ScreenTimeApp/" --include="*.swift" | grep -v ".numberPad"; then
    echo "❌ Found remaining incorrect .number usage"
    exit 1
else
    echo "✅ No remaining incorrect .number usage found"
fi

# Check that there are no remaining incorrect .decimal references in Swift files
if grep -r "\.decimal\b" "Apps/ScreenTimeApp/ScreenTimeApp/" --include="*.swift" | grep -v ".decimalPad"; then
    echo "❌ Found remaining incorrect .decimal usage"
    exit 1
else
    echo "✅ No remaining incorrect .decimal usage found"
fi

echo "All keyboard type fixes verified successfully!"
echo ""
echo "The NumericSettingView should now build correctly with:"
echo "  - .numberPad keyboard for integer values"
echo "  - .decimalPad keyboard for decimal values"