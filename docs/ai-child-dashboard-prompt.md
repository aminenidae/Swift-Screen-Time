# AI Prompt Specification for Screen Time Rewards Child Dashboard Components

This document provides detailed prompts for AI-assisted generation of the Screen Time Rewards Child Dashboard components. These prompts follow the UI/UX specification and are designed to generate SwiftUI code that aligns with Apple's Human Interface Guidelines and the app's existing design system.

## 1. Overall Child Dashboard Structure

Create a comprehensive Child Dashboard for Screen Time Rewards with the following structure:

1. Tab-based navigation with Dashboard, Rewards, and Profile tabs
2. Dashboard tab containing:
   - Progress overview with visual indicators
   - Recent learning activity feed
   - Daily goals tracking
3. Rewards tab containing:
   - Points balance display
   - Entertainment apps for unlock
   - Special rewards
   - Recent redemptions history
4. Profile tab containing:
   - Child profile information
   - Stats and achievements
   - Profile settings

All components should:
- Follow Apple's Human Interface Guidelines
- Use the app's color palette (#4A90E2 primary, #50C878 secondary, #FFD700 accent)
- Implement proper accessibility features
- Support Dynamic Type
- Maintain consistent spacing using 8px grid system
- Include smooth animations and transitions
- Be engaging and fun for children

## 2. ChildMainView Component

Create a SwiftUI View for the child main dashboard with these specifications:

- TabView container with three tabs (Dashboard, Rewards, Profile)
- Dashboard tab containing:
  - NavigationStack for proper navigation
  - ScrollView for vertical layout
  - ProgressDashboard component showing:
    - Daily points progress
    - Weekly points progress
    - Current streak information
    - Longest streak information
    - Learning minutes progress
  - Recent learning activity section with:
    - Section title "Recent Learning"
    - List of LearningActivityRow components
  - Proper padding and spacing
  - Navigation title "My Dashboard"
  - Pull-to-refresh functionality
- Integration with point tracking services
- Points earned animations overlay
- Milestone celebration overlay
- Support for dark mode

## 3. ProgressDashboard Component

Create a SwiftUI View for displaying child progress with visual indicators:

- Vertical layout with multiple progress indicators
- Daily points progress ring showing:
  - Current points
  - Daily goal
  - Percentage completion
- Weekly points progress bar showing:
  - Weekly points
  - Weekly goal
  - Percentage completion
- Streak information showing:
  - Current streak with flame icon
  - Longest streak for motivation
- Learning minutes progress showing:
  - Today's learning minutes
  - Daily learning goal
- Consistent color scheme (yellow for points, orange for streaks, green for learning)
- Accessible with proper labels
- Responsive to different screen sizes
- Smooth animations for progress updates

## 4. LearningActivityRow Component

Create a SwiftUI View for displaying recent learning activities:

- Horizontal layout with app information and points
- App name in bold text
- Duration and time ago in secondary text
- Points earned with star icon in green
- Consistent styling with app's design system
- Proper padding and background
- Accessible with proper labels
- Support for different app types

## 5. RewardsView Component

Create a SwiftUI View for the child rewards interface:

- ScrollView container with vertical layout
- Points balance header showing:
  - Large points display with star icon
  - "Available Points" label
  - Visually appealing design
- Entertainment apps section with:
  - Section title "Available Entertainment Apps"
  - List of EntertainmentAppUnlockCard components
- Recent redemptions section with:
  - Section title "Recent Redemptions"
  - List of RecentRedemptionRow components
- Proper padding and spacing
- Navigation title "Rewards"
- Pull-to-refresh functionality
- Integration with family controls service

## 6. EntertainmentAppUnlockCard Component

Create a SwiftUI View for displaying entertainment apps that can be unlocked:

- Card-based design with app information
- App icon or placeholder
- App name in bold text
- Point costs for different durations (30min, 60min)
- Unlock buttons for each duration
- Visual indication of unlocked status
- Proper disabled states for unaffordable options
- Consistent styling with app's design system
- Accessible with proper labels
- Support for different app categories

## 7. RecentRedemptionRow Component

Create a SwiftUI View for displaying recent reward redemptions:

- Horizontal layout with reward information
- Reward name and cost
- Redemption timestamp
- Status indicator
- Consistent styling with app's design system
- Proper padding and background
- Accessible with proper labels

## 8. ChildProfileView Component

Create a SwiftUI View for the child profile interface:

- ScrollView container with vertical layout
- Profile header showing:
  - Child avatar or placeholder
  - Child name
  - Fun title or badge
- Stats section with:
  - Section title "Your Stats"
  - ProfileStatCard components for:
    - Total points
    - Learning hours
    - Current streak
- Profile switching section with:
  - Section title "Account"
  - Button to ProfileSwitcherView
- Proper padding and spacing
- Navigation title "Profile"

## 9. Supporting Components

Create the following reusable components:

### ProfileStatCard Component
- Card-based design for displaying child statistics
- Icon, value, and title layout
- Consistent styling and sizing
- Color-coded icons
- Accessible with proper labels

### ProfileSwitcherView Component
- Modal view for switching between parent and child profiles
- Clear options for each profile type
- Visual indication of current selection
- Done button to close modal

### ProfileOptionCard Component
- Card-based design for profile options
- Icon, title, and subtitle layout
- Visual feedback for selection
- Consistent styling with app's design system

### FloatingPointsNotification Component
- Overlay view for showing points earned
- Animated entry and exit
- Clear point display with star icon
- Auto-dismiss functionality
- Accessible with proper labels

### MilestoneCelebration Component
- Overlay view for celebrating achievements
- Trophy icon or other celebration graphics
- Title and subtitle messaging
- Auto-dismiss functionality
- Accessible with proper labels

## 10. State Management and Data Flow

Implement proper state management:

- Use @State for local UI state
- Use @StateObject for shared services (PointTrackingService, StreakTrackingService)
- Implement proper data loading and error handling
- Support for real-time point tracking updates
- Efficient view updates
- Proper cleanup of observers

## 11. Animations and Micro-interactions

Implement engaging animations:

- Points earned floating notifications
- Progress ring animations
- Button tap feedback
- Card selection states
- Modal transitions
- Milestone celebrations

## 12. Accessibility Features

Ensure all components include:

- Proper VoiceOver labels and hints
- Sufficient color contrast (4.5:1 for text)
- Dynamic Type support
- Keyboard navigation support
- Focus indicators for interactive elements
- Semantic headings structure

## 13. Performance Considerations

Optimize for performance:

- Efficient view updates
- Minimal redraws
- Proper use of LazyVStack where appropriate
- Image optimization
- Asynchronous loading for network operations
- Memory-efficient animations

## 14. Code Quality Standards

Generated code should follow these standards:

- Clean, readable SwiftUI implementation
- Proper separation of concerns
- Consistent naming conventions
- Comprehensive documentation comments
- Error handling for edge cases
- Unit testability
- Preview providers for Xcode canvas