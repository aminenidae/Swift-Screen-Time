# AI Prompt Specification for Screen Time Rewards Parent Dashboard Components

This document provides detailed prompts for AI-assisted generation of the Screen Time Rewards Parent Dashboard components. These prompts follow the UI/UX specification and are designed to generate SwiftUI code that aligns with Apple's Human Interface Guidelines and the app's existing design system.

## 1. Overall Parent Dashboard Structure

Create a comprehensive Parent Dashboard for Screen Time Rewards with the following structure:

1. Tab-based navigation with Dashboard, Family, and Settings tabs
2. Dashboard tab containing:
   - Family statistics overview
   - Children progress cards
   - Recent activity feed
   - Quick action buttons
3. Family tab containing:
   - Child-specific settings access
   - Family management tools
4. Settings tab containing:
   - General app settings
   - Child-specific configuration

All components should:
- Follow Apple's Human Interface Guidelines
- Use the app's color palette (#4A90E2 primary, #50C878 secondary, #FFD700 accent)
- Implement proper accessibility features
- Support Dynamic Type
- Maintain consistent spacing using 8px grid system
- Include smooth animations and transitions

## 2. ParentDashboardView Component

Create a SwiftUI View for the parent dashboard with these specifications:

- ScrollView container with vertical layout
- Family statistics header showing:
  - Number of children
  - Total family points
  - Active children today
- Children progress section with:
  - Section title "Children's Progress"
  - Individual child progress cards showing:
    - Child name and avatar
    - Current points balance
    - Daily learning minutes
    - Current streak
    - Quick access to child settings
  - Empty state when no children found with:
    - Illustration showing no children
    - Clear message about Family Sharing setup
    - Button to Family Setup view
- Recent activity feed showing:
  - Section title "Recent Activity"
  - List of recent family activities with:
    - Child name and initial avatar
    - Activity description
    - Points earned/spent
    - Time ago
- Quick actions section with:
  - Section title "Quick Actions"
  - Grid of action cards for:
    - Family Setup
    - Reports
    - Time Limits
    - App Categories
- Use consistent styling with the app's design system
- Support dark mode with appropriate color adjustments
- Include pull-to-refresh functionality

## 3. OverviewStatCard Component

Create a reusable SwiftUI View for displaying family statistics:

- Vertical layout with icon, value, and title
- Consistent sizing and padding
- Color-coded icons matching data type (blue for children, yellow for points, green for active)
- Support for large numbers with proper formatting
- Accessible with proper labels
- Responsive to different screen sizes

## 4. ChildProgressCard Component

Create a SwiftUI View for displaying individual child progress:

- Horizontal layout with child information and progress indicators
- Child avatar or initial with color coding
- Child name and status indicator (app installed/not installed)
- Points balance with star icon
- Daily learning minutes with book icon
- Current streak with flame icon
- Quick action button to access child settings
- Visual progress indicator for daily goals
- Support for different states (normal, selected, inactive)
- Accessible with proper labels and hints

## 5. RecentActivityRow Component

Create a SwiftUI View for displaying recent family activity:

- Horizontal layout with child avatar, activity info, and points
- Child initial avatar with color coding
- Child name in bold
- Activity description in regular text
- Points earned/spent with appropriate color (green for earned, orange for spent)
- Time ago in secondary text
- Support for different activity types (learning, reward redemption, milestones)
- Accessible with proper labels

## 6. QuickActionCard Component

Create a reusable SwiftUI View for quick action buttons:

- Card-based design with icon, title, and tap target
- Consistent sizing and corner radius
- Color-coded icons
- Clear, actionable titles
- Visual feedback on tap
- Accessible with proper labels

## 7. ParentFamilyView Component

Create a SwiftUI View for the family management tab:

- List-based layout with sections
- Child settings section showing:
  - App Categories
  - Learning Apps
  - Reward Apps
  - Special Rewards
  - Daily Time Limits
  - Detailed Reports
  - Usage Trends
- Empty state when no children found with:
  - Illustration showing no children
  - Clear message about Family Sharing
  - Button to Family Setup view
- Navigation links to child-specific views
- Support for dynamic child list updates

## 8. ParentSystemSettingsView Component

Create a SwiftUI View for the settings tab:

- Container view that integrates with existing SettingsContainerView
- Tab-based navigation or list structure
- Proper integration with navigation hierarchy
- Support for dark mode

## 9. Supporting Components

Create the following reusable components:

### SubscriptionStatusIndicator Component
- Small banner showing subscription status
- Different styling for free vs premium users
- Link to subscription management

### SettingsSummaryView Component
- Quick access to common settings
- Grid layout with setting cards
- Navigation to full settings views

### FamilySetupView Integration
- Proper navigation to family setup flow
- Consistent styling with rest of app

## 10. State Management and Data Flow

Implement proper state management:

- Use @StateObject for FamilyMemberService
- Use @State for local UI state
- Implement proper data loading and error handling
- Support for pull-to-refresh
- Efficient view updates

## 11. Accessibility Features

Ensure all components include:

- Proper VoiceOver labels and hints
- Sufficient color contrast (4.5:1 for text)
- Dynamic Type support
- Keyboard navigation support
- Focus indicators for interactive elements
- Semantic headings structure

## 12. Performance Considerations

Optimize for performance:

- Efficient view updates
- Minimal redraws
- Proper use of LazyVStack where appropriate
- Image optimization
- Asynchronous loading for network operations
- Memory-efficient animations

## 13. Code Quality Standards

Generated code should follow these standards:

- Clean, readable SwiftUI implementation
- Proper separation of concerns
- Consistent naming conventions
- Comprehensive documentation comments
- Error handling for edge cases
- Unit testability
- Preview providers for Xcode canvas