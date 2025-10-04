#!/bin/bash

# Verification script for PrivacyPolicyView redeclaration fix
echo "=== Verifying PrivacyPolicyView Redefinition Fix ==="

# Check that there's only one PrivacyPolicyView definition now
COUNT=$(grep -r "struct PrivacyPolicyView" Apps/ScreenTimeApp/ScreenTimeApp/ | wc -l)

if [ $COUNT -eq 1 ]; then
    echo "✅ Only one PrivacyPolicyView definition found"
else
    echo "❌ Found $COUNT PrivacyPolicyView definitions (should be 1)"
    exit 1
fi

# Check that the AnalyticsPrivacyPolicyView was created
if grep -q "struct AnalyticsPrivacyPolicyView" "Apps/ScreenTimeApp/ScreenTimeApp/Features/Analytics/AnalyticsSettingsView.swift"; then
    echo "✅ AnalyticsPrivacyPolicyView definition found"
else
    echo "❌ AnalyticsPrivacyPolicyView definition not found"
    exit 1
fi

# Check that the reference was updated
if grep -q "AnalyticsPrivacyPolicyView()" "Apps/ScreenTimeApp/ScreenTimeApp/Features/Analytics/AnalyticsSettingsView.swift"; then
    echo "✅ Reference to AnalyticsPrivacyPolicyView found"
else
    echo "❌ Reference to AnalyticsPrivacyPolicyView not found"
    exit 1
fi

echo "PrivacyPolicyView redeclaration fix verification completed successfully!"
echo ""
echo "The build error should now be resolved with:"
echo "  - PrivacyPolicyView in SettingsPreferencesView (general privacy policy)"
echo "  - AnalyticsPrivacyPolicyView in AnalyticsSettingsView (analytics-specific privacy policy)"