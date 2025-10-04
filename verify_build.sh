#!/bin/bash

# Verification script for ScreenTime Rewards settings implementation
echo "Verifying ScreenTime Rewards settings implementation..."

# Navigate to the project directory
cd "$(dirname "$0")"

# Check if all required files exist
echo "Checking for required files..."

REQUIRED_FILES=(
  "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/SettingsContainerView.swift"
  "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/SettingsDashboardView.swift"
  "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/SettingsGroupView.swift"
  "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/NumericSettingView.swift"
  "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/ConfirmationToggleView.swift"
  "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/SettingsService.swift"
  "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/SettingsPreferencesView.swift"
  "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/SettingsSummaryView.swift"
  "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/ChildSelectionView.swift"
)

MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "❌ Missing file: $file"
    MISSING_FILES+=("$file")
  else
    echo "✅ Found file: $file"
  fi
done

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
  echo "✅ All required files are present"
else
  echo "❌ Missing ${#MISSING_FILES[@]} required files"
  exit 1
fi

# Check if ParentMainView uses the new SettingsContainerView
echo "Checking ParentMainView integration..."

if grep -q "SettingsContainerView()" "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentDashboard/ParentMainView.swift"; then
  echo "✅ ParentMainView correctly uses SettingsContainerView"
else
  echo "❌ ParentMainView does not use SettingsContainerView"
  exit 1
fi

# Check if SettingsDashboardView has the correct structure
echo "Checking SettingsDashboardView implementation..."

if grep -q "ChildSelectionView.ChildSettingDestination" "Apps/ScreenTimeApp/ScreenTimeApp/Features/ParentSettings/SettingsDashboardView.swift"; then
  echo "✅ SettingsDashboardView has correct ChildSettingDestination usage"
else
  echo "❌ SettingsDashboardView missing ChildSettingDestination usage"
  exit 1
fi

echo "✅ All verification checks passed!"
echo ""
echo "To build and run the project:"
echo "  1. Open Xcode: open -a Xcode ScreenTimeRewards.xcworkspace"
echo "  2. Select the ScreenTimeApp scheme"
echo "  3. Choose an iOS Simulator as target"
echo "  4. Build and run the project (Cmd+R)"