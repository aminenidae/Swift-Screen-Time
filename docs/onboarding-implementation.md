# Screen Time Rewards Onboarding Implementation

This document provides an overview of the upgraded onboarding flow implementation for Screen Time Rewards.

## Overview

The new onboarding flow provides a comprehensive, role-specific introduction to Screen Time Rewards that guides both parents and children through the key concepts and setup process.

## Components

### Main Components

1. **OnboardingView** - Main coordinator that manages the onboarding flow
2. **WelcomeView** - Initial welcome screen
3. **RoleSelectionView** - Allows users to select their role (parent or child)
4. **ParentOnboardingView** - Multi-step onboarding for parents
5. **ChildOnboardingView** - Multi-step onboarding for children

### Supporting Components

1. **OnboardingProgressView** - Progress indicator showing current step
2. **RoleCard** - Reusable card for role selection
3. **OnboardingBenefitRow** - Row component for displaying benefits
4. **RewardExampleRow** - Row component for reward examples

## Parent Onboarding Flow

The parent onboarding consists of three steps:

1. **Family Setup Introduction** - Explains how Family Sharing works with the app
2. **Family Details** - Collects parent/family name and syncs family members
3. **Reward System Introduction** - Explains how the reward system works

## Child Onboarding Flow

The child onboarding consists of three steps:

1. **Child Introduction** - Welcomes the child and introduces the concept
2. **Points Explanation** - Explains how to earn points
3. **Redeeming Guide** - Shows how to redeem points for rewards

## Key Features

### Progressive Disclosure
The onboarding flow reveals information gradually to avoid overwhelming users.

### Role-Specific Content
Different flows for parents and children with appropriate messaging and visuals.

### Family Member Sync
Parents can sync their family members directly during onboarding.

### Visual Design
- Consistent with the app's design system
- Uses appropriate colors for each role (blue for parents, green for children)
- Accessible with proper contrast and Dynamic Type support
- Engaging animations and visual feedback

### Navigation
- Clear progress indicator
- Back button to previous steps
- Skip option to bypass onboarding
- Smooth transitions between steps

## Implementation Details

### State Management
- Uses @AppStorage to persist user role and onboarding completion status
- Uses @StateObject for FamilyMemberService in parent onboarding
- Local @State for form fields and UI state

### Navigation
- Uses NavigationStack for smooth transitions
- Step-based navigation with progress tracking
- Conditional navigation based on user role

### Data Flow
- FamilyMemberService integration for syncing family members
- Error handling for network operations
- Loading states for async operations

## Files

All onboarding components are located in:
`/Apps/ScreenTimeApp/ScreenTimeApp/Features/Onboarding/`

- OnboardingView.swift
- OnboardingProgressView.swift
- WelcomeView.swift
- RoleSelectionView.swift
- ParentOnboardingView.swift
- ChildOnboardingView.swift

## Integration

The onboarding flow is integrated into the main app through ContentView.swift, which checks the `hasCompletedOnboarding` flag to determine whether to show the onboarding flow or the main app interface.

## Next Steps

1. Conduct usability testing with parent and child users
2. Gather feedback and iterate on the design
3. Add analytics to track onboarding completion rates
4. Consider adding tooltips or additional guidance for complex steps
5. Implement localization for different languages