# ScreenTime Rewards App - UI Views Documentation

This document provides a comprehensive list of all UI view pages in the ScreenTime Rewards application with their definitions and descriptions.

## Main Views

### 1. ContentView.swift
**Description**: The main entry point of the application that determines which view to display based on user role and onboarding status.
**Key Functionality**: 
- Routes users to either the onboarding flow or the appropriate dashboard based on their role (parent or child)
- Manages user role and onboarding state using AppStorage

### 2. OnboardingView
**Description**: The comprehensive onboarding flow that guides new users through setting up ScreenTime Rewards.
**Key Functionality**: 
- Welcomes new users to the app
- Allows users to select their role (Parent or Child)
- Provides role-specific onboarding experiences
- Integrates family member syncing for parents
- Explains the reward system for both roles
- Sets the user role in AppStorage
- Marks onboarding as complete

## Parent Views

### 3. ParentMainView.swift
**Description**: The main dashboard view for parents with tab navigation.
**Key Functionality**: 
- Provides tab-based navigation to Family Overview, Activity, and Settings
- Serves as the primary navigation hub for parent features

### 4. FamilyOverviewView.swift
**Description**: The family dashboard showing children's progress and family statistics.
**Key Functionality**: 
- Displays family statistics (number of children, total points, active children)
- Shows individual child progress cards
- Provides quick actions for family setup, time limits, and reports
- Handles empty state when no children are found

### 5. ParentSettingsView.swift
**Description**: The main settings view for parents with various configuration options.
**Key Functionality**: 
- General settings for family setup, family controls, and family members
- Reward system configuration for learning app points and reward costs
- Child-specific settings for learning apps, activity, reward apps, time limits, bedtime, reports, and usage trends
- Account management options

## Child Views

### 6. ChildMainView.swift
**Description**: The main dashboard view for children to see their progress and recent activity.
**Key Functionality**: 
- Tab-based navigation to Dashboard, Rewards, and Profile
- Displays current points, daily goals, streaks, and learning minutes
- Shows recent learning activity
- Integrates with point tracking and streak tracking services
- Provides visual feedback for point earning and milestone achievements

### 7. ChildProfileView.swift
**Description**: The profile view for children to see their personal information and achievements.
**Key Functionality**: 
- Displays child profile information
- Shows achievements and milestones
- Provides options for profile customization

## Rewards System Views

### 8. RewardsView.swift
**Description**: The main rewards view where children can redeem points for entertainment apps and other rewards.
**Key Functionality**: 
- Displays current point balance
- Shows available entertainment apps for unlock
- Allows children to redeem points for app access time
- Displays recent redemptions history
- Integrates with family controls service for app unlocking

## Subscription Views

### 9. PaywallView.swift
**Description**: The main paywall view for subscription purchases.
**Key Functionality**: 
- Displays premium features available with subscription
- Shows available subscription plans
- Handles subscription purchase flow
- Provides restore purchases functionality

### 10. SubscriptionManagementView.swift
**Description**: View for managing active subscriptions and viewing subscription details.
**Key Functionality**: 
- Displays current subscription status
- Shows subscription plan details
- Provides options to manage subscription

### 11. SubscriptionOnboardingView.swift
**Description**: Onboarding view for introducing subscription benefits to new users.
**Key Functionality**: 
- Educates users about premium features
- Guides users through subscription benefits

### 12. SubscriptionStatusIndicator.swift
**Description**: A component that displays the current subscription status.
**Key Functionality**: 
- Shows subscription status in other views
- Provides upgrade prompts for free users

## Authentication & Sync Views

### 13. iCloudSettingsView.swift
**Description**: Comprehensive iCloud settings and management interface.
**Key Functionality**: 
- Displays iCloud account status
- Manages sync status and manual sync options
- Handles offline data management
- Provides troubleshooting tools

### 14. iCloudSyncStatusView.swift
**Description**: View for displaying iCloud synchronization status.
**Key Functionality**: 
- Shows current sync status
- Provides visual indicators for sync state

## Supporting Views

### 15. ActivityView
**Description**: View for displaying screen time activity and usage statistics.
**Key Functionality**: 
- Shows detailed activity reports
- Displays usage patterns and trends

### 16. ChildProgressCard
**Description**: Card component for displaying individual child progress.
**Key Functionality**: 
- Shows child's points, learning minutes, and streak
- Provides visual representation of progress

### 17. EntertainmentAppUnlockCard
**Description**: Card component for displaying entertainment apps that can be unlocked.
**Key Functionality**: 
- Shows app information and unlock costs
- Allows users to unlock apps with points

### 18. OverviewStatCard
**Description**: Card component for displaying overview statistics.
**Key Functionality**: 
- Shows key metrics with icons and colors
- Provides at-a-glance family statistics

### 19. ProgressDashboard
**Description**: Component for displaying progress metrics and goals.
**Key Functionality**: 
- Shows daily and weekly points progress
- Displays streak information
- Visualizes goal achievement

### 20. LearningActivityRow
**Description**: Row component for displaying learning activity information.
**Key Functionality**: 
- Shows app name, duration, points earned, and time ago
- Provides detailed view of learning activities

This documentation provides a comprehensive overview of all UI views in the ScreenTime Rewards application, detailing their purpose and key functionality.