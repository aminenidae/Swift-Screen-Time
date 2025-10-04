# AI Prompt Specification for Screen Time Rewards Onboarding Components

This document provides detailed prompts for AI-assisted generation of the Screen Time Rewards onboarding flow components. These prompts follow the UI/UX specification and are designed to generate SwiftUI code that aligns with Apple's Human Interface Guidelines and the app's existing design system.

## 1. Overall Onboarding Flow Structure

Create a comprehensive onboarding flow for Screen Time Rewards with the following structure:

1. Welcome screen introducing the app
2. Role selection (parent or child)
3. Parent onboarding (3 steps):
   - Family setup introduction
   - Enter parent/family name and sync family members
   - Reward system introduction
4. Child onboarding (3 steps):
   - Child introduction
   - Points and rewards explanation
   - Earning and redeeming guide
5. Completion screen leading to the main dashboard

All components should:
- Follow Apple's Human Interface Guidelines
- Use the app's color palette (#4A90E2 primary, #50C878 secondary, #FFD700 accent)
- Implement proper accessibility features
- Support Dynamic Type
- Maintain consistent spacing using 8px grid system
- Include smooth animations and transitions

## 2. WelcomeView Component

Create a SwiftUI View for the welcome screen with these specifications:

- Large, friendly app icon or illustration
- Engaging headline: "Transform Screen Time into Learning Time"
- Brief, benefit-focused description: "Earn rewards for educational activities and unlock fun time with ScreenTime Rewards"
- "Get Started" primary button
- Skip onboarding option in navigation bar
- Use SF Pro fonts with appropriate sizing (H1 for headline, body for description)
- Center content vertically and horizontally
- Include subtle animation for the icon/illustration
- Support dark mode with appropriate color adjustments

## 3. RoleSelectionView Component

Create a SwiftUI View for role selection with these specifications:

- Clear title: "Who is using this device?"
- Two large, distinct cards for "I'm a Parent" and "I'm a Child"
- Parent card:
  - Icon: person.2.circle.fill (blue color)
  - Title: "I'm a Parent"
  - Description: "Set up family members and manage rewards"
- Child card:
  - Icon: person.circle.fill (green color)
  - Title: "I'm a Child"
  - Description: "Earn points and unlock rewards"
- Large, tappable cards with appropriate padding
- Visual feedback on selection
- Continue button (enabled when role is selected)
- Back button to welcome screen
- Progress indicator showing "Step 1 of X"
- Consistent with app's color scheme and typography

## 4. ParentOnboardingView Component

Create a multi-step SwiftUI View for parent onboarding:

### Step 1: Family Setup Introduction
- Title: "Set Up Your Family"
- Illustration showing family members
- Explanation: "ScreenTime Rewards works with Apple Family Sharing to manage your children's screen time"
- Key benefits:
  - "See all your children's activity in one place"
  - "Set individual goals and rewards"
  - "Track learning progress across devices"
- "Continue" button

### Step 2: Enter Parent/Family Name and Sync Family Members
- Title: "Your Family Details"
- Two text fields:
  - "Your Name" (parent name)
  - "Family Name" (optional)
- "Sync Family Members" button that triggers FamilyMemberService
- Loading state during sync
- Display of synced family members with:
  - Child name
  - App installed status indicator
  - Visual avatar
- Empty state with guidance if no family members found
- Back and Continue buttons

### Step 3: Reward System Introduction
- Title: "How Rewards Work"
- Illustration showing points and rewards
- Explanation: "Children earn points for using educational apps and can redeem them for entertainment time"
- Key concepts:
  - "Learning Apps = Earn Points"
  - "Entertainment Apps = Spend Points"
  - "Set daily goals for consistent learning"
- "Continue" button

## 5. ChildOnboardingView Component

Create a multi-step SwiftUI View for child onboarding:

### Step 1: Child Introduction
- Title: "Welcome! Let's Learn and Earn Rewards!"
- Fun, colorful illustration
- Simple explanation: "Use learning apps to earn points, then spend them to unlock fun time!"
- Friendly character or mascot
- "Continue" button

### Step 2: Points and Rewards Explanation
- Title: "Earning Points"
- Visual representation of points (stars or coins)
- Explanation: "You earn 1 point for every minute you use learning apps like Khan Academy or Duolingo"
- Examples of learning apps with icons
- "Continue" button

### Step 3: Earning and Redeeming Guide
- Title: "Redeeming Rewards"
- Explanation: "Save your points to unlock entertainment apps like YouTube or games"
- Visual showing point cost examples:
  - "15 points = 15 minutes of YouTube"
  - "30 points = 30 minutes of Minecraft"
- Encouraging message: "The more you learn, the more fun you can have!"
- "Continue" button

## 6. CompletionView Component

Create a SwiftUI View for the onboarding completion screen:

- Celebration animation or illustration
- Title: "You're All Set!"
- Personalized message based on role:
  - Parent: "Your family is ready to start earning rewards for learning time"
  - Child: "You're ready to earn points and unlock rewards!"
- Summary of next steps:
  - Parent: "Set up learning apps, configure rewards, and start tracking progress"
  - Child: "Open learning apps to start earning points!"
- "Go to Dashboard" primary button
- Progress indicator showing completion

## 7. Supporting Components

Create the following reusable components:

### ProgressIndicator Component
- Linear progress bar or step counter
- Shows current step and total steps
- Animated transitions between steps
- Accessible with proper labeling

### OnboardingCard Component
- Reusable card for onboarding content
- Consistent padding and corner radius
- Proper shadow or border for depth
- Support for header, content, and footer areas

### BenefitRow Component
- Horizontal layout with icon, title, and description
- Consistent spacing and alignment
- Appropriate font weights and sizes
- Reusable across multiple screens

### ActionButton Component
- Primary and secondary button styles
- Proper sizing and padding
- Visual feedback on tap
- Loading state support
- Accessible with proper labeling

## 8. State Management and Navigation

Implement proper state management and navigation:

- Use @State and @Binding for local state
- Use @StateObject for shared services like FamilyMemberService
- Implement NavigationStack for smooth transitions
- Handle loading states appropriately
- Implement error handling for network operations
- Store onboarding completion status using @AppStorage

## 9. Accessibility Features

Ensure all components include:

- Proper VoiceOver labels and hints
- Sufficient color contrast (4.5:1 for text)
- Dynamic Type support
- Keyboard navigation support
- Focus indicators for interactive elements
- Semantic headings structure

## 10. Performance Considerations

Optimize for performance:

- Efficient view updates
- Minimal redraws
- Proper use of LazyVStack where appropriate
- Image optimization
- Asynchronous loading for network operations
- Memory-efficient animations

## 11. Code Quality Standards

Generated code should follow these standards:

- Clean, readable SwiftUI implementation
- Proper separation of concerns
- Consistent naming conventions
- Comprehensive documentation comments
- Error handling for edge cases
- Unit testability
- Preview providers for Xcode canvas