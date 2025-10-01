# Apple Developer Console Configuration Required

⚠️ **IMPORTANT**: The following configurations must be completed in the Apple Developer Console before this app can be built and submitted to the App Store.

## 1. App Identifier Setup

Create a new App Identifier with:
- **Bundle ID**: `com.screentimerewards.app`
- **Name**: Screen Time Rewards

**Required Capabilities:**
- ✅ App Groups
- ✅ Family Controls (Development)
- ✅ iCloud (CloudKit and Key-Value Storage)
- ✅ Push Notifications

## 2. App Groups Configuration

Create App Group:
- **Identifier**: `group.com.screentimerewards.app`
- **Description**: Screen Time Rewards App Group

## 3. CloudKit Container Setup

Create CloudKit Container:
- **Identifier**: `iCloud.com.screentimerewards.app`
- **Name**: Screen Time Rewards Container

## 4. Provisioning Profiles

Create new provisioning profiles for:

### Development Profile
- **Type**: Development
- **App ID**: com.screentimerewards.app
- **Include all development devices**

### Distribution Profile
- **Type**: App Store Distribution
- **App ID**: com.screentimerewards.app

## 5. Xcode Configuration

After creating the above in Apple Developer Console:

1. **Download and install the new provisioning profiles**
2. **Update Xcode project settings:**
   - Team: Select your development team
   - Bundle Identifier: com.screentimerewards.app (already updated)
   - Provisioning Profile: Select the new development profile

## 6. CloudKit Database Schema

⚠️ **CRITICAL**: The CloudKit database needs to be configured with the correct schema for the app's data models.

Review and deploy the schema from the CloudKitService package to the new container.

## 7. Family Controls Permission

The app uses Family Controls which requires:
- Special entitlement approval from Apple
- Detailed explanation of usage in App Store Review
- Privacy policy that clearly explains data collection

## 8. App Store Connect Setup

Before submission:
1. Create new app in App Store Connect
2. Configure app metadata, descriptions, screenshots
3. Set up pricing and availability
4. Configure Family Sharing settings if applicable

## Notes

- The bundle identifiers have been updated throughout the project
- Privacy usage descriptions have been added to Info.plist
- APS environment is set to production
- App icon placeholder structure is ready (actual icons needed)

## Next Steps

1. Complete Apple Developer Console configuration above
2. Create and install actual app icons
3. Test on physical device with Family Controls
4. Submit for App Store Review