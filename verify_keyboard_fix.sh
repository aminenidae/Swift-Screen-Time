#!/bin/bash

# Verification script for keyboard type fix
echo "=== Verifying Keyboard Type Fix ==="

# Check if the fix was applied correctly
if grep -q "keyboardType(isInteger ? .numberPad : .decimalPad)" "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/NumericSettingView.swift"; then
    echo "✅ Correct keyboardType usage found"
else
    echo "❌ Fix not applied correctly"
    exit 1
fi

# Check if there are any remaining incorrect usages
if grep -r "\.decimal" "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/" --include="*.swift"; then
    echo "❌ Found remaining incorrect .decimal usage"
    exit 1
else
    echo "✅ No remaining incorrect .decimal usage found"
fi

echo "Keyboard type fix verification completed successfully!"
echo ""
echo "The NumericSettingView should now build correctly with:"
echo "  - .numberPad keyboard for integer values"
echo "  - .decimalPad keyboard for decimal values"