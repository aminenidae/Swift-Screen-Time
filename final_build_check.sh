#!/bin/bash

# Final build verification script
echo "=== Final Build Verification ==="
echo "Checking for duplicate SettingsSummaryView files..."

# Count occurrences of SettingsSummaryView.swift
COUNT=$(find . -name "SettingsSummaryView.swift" | wc -l)

if [ $COUNT -eq 1 ]; then
    echo "✅ Only one SettingsSummaryView.swift file found"
else
    echo "❌ Found $COUNT SettingsSummaryView.swift files (should be 1)"
    find . -name "SettingsSummaryView.swift"
    exit 1
fi

echo "Checking ParentMainView imports..."
if grep -q "SettingsSummaryView" "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentDashboard/ParentMainView.swift"; then
    echo "✅ ParentMainView references SettingsSummaryView"
else
    echo "❌ ParentMainView does not reference SettingsSummaryView"
    exit 1
fi

echo "All checks passed! The build conflict should be resolved."
echo ""
echo "To build the project, open Xcode:"
echo "  open -a Xcode ScreenTimeRewards.xcworkspace"
echo ""
echo "Then build and run using Xcode's interface."