# AI Frontend Prompt for Screen Time Rewards App

## Project Context

Screen Time Rewards is an iOS application built with Swift/SwiftUI that helps parents create a positive relationship between their children and technology by rewarding productive screen time activities. Children earn points for educational app usage, reading, and creative activities, which can be redeemed for rewards set by parents.

## Tech Stack

- iOS 15.0+
- Swift 5.5+
- SwiftUI
- Swift Package Manager
- CloudKit for data synchronization
- Family Controls framework for screen time management
- StoreKit 2 for subscription management

## Visual Style

- Clean, modern interface with rounded corners
- Family-friendly color palette with blues (#4A90E2) for primary actions, greens (#50C878) for success states, and golds (#FFD700) for rewards
- Card-based layout for content organization
- Consistent spacing using an 8px grid system
- Accessible typography with appropriate contrast ratios
- Tab-based navigation for main sections

## Prompt for AI UI Generation Tool

```
You are an expert iOS SwiftUI developer tasked with creating UI components for a family screen time management application called "Screen Time Rewards". 

HIGH-LEVEL GOAL:
Create a responsive, accessible, and visually appealing SwiftUI component for the Parent Dashboard that displays family overview statistics and child progress cards.

DETAILED INSTRUCTIONS:
1. Create a new SwiftUI View file named "FamilyOverviewView.swift"
2. Implement a tab-based parent dashboard with "Family", "Activity", and "Settings" tabs
3. The Family tab should display:
   - Header with welcome message and family name
   - Summary statistics cards showing:
     * Total children in family
     * Total points earned this week
     * Active children today
   - Grid of child progress cards showing:
     * Child name and avatar
     * Current points balance
     * Daily learning goal progress
     * Streak count
   - Action buttons for "Add Child", "Set Time Limits", and "View Reports"
4. Use a clean, modern design with:
   - Rounded corners (8pt radius)
   - Consistent spacing (8px grid)
   - Blue primary color (#4A90E2)
   - Appropriate typography hierarchy
5. Ensure the design is responsive and works on different iOS device sizes
6. Implement proper accessibility support with labels and hints
7. Use SF Symbols for icons where appropriate

CODE EXAMPLES AND CONSTRAINTS:
- Follow Apple's Human Interface Guidelines
- Use SwiftUI best practices (State, Binding, ObservableObject)
- Structure code with clear separation of concerns
- Use LazyVGrid for the child cards grid
- Implement proper error handling for data loading
- Do NOT use UIKit - this is a pure SwiftUI project
- Do NOT include backend logic - focus only on UI components

STRICT SCOPE:
Create only the FamilyOverviewView.swift component and any supporting view models or helper structs needed for this view. Do not modify any existing files or create additional views beyond what's needed for this component.

MOBILE-FIRST APPROACH:
Design for iPhone first, then consider how the layout should adapt for iPad. Use size classes appropriately for responsive design.
```

## Component-Specific Prompts

### Child Progress Card Component

```
Create a reusable SwiftUI component for displaying individual child progress in the Screen Time Rewards app.

HIGH-LEVEL GOAL:
Design a visually appealing card component that clearly shows a child's progress metrics and encourages continued engagement.

DETAILED INSTRUCTIONS:
1. Create a SwiftUI View named "ChildProgressCard.swift"
2. The card should display:
   - Child's name and avatar (circular image)
   - Current points balance with prominent display
   - Daily learning goal progress (circular or linear progress indicator)
   - Streak count with flame icon
   - Last activity time
3. Include a subtle shadow and rounded corners
4. Use a consistent color scheme with the app's blue primary color
5. Implement proper accessibility labels
6. Make the card tappable to navigate to detailed child view

VISUAL STYLE:
- Card dimensions: Flexible width, ~120pt height
- Avatar size: 40pt diameter
- Points display: Large, bold text
- Progress indicator: Circular with 40pt diameter
- Background: Light gray/white with subtle border

CONSTRAINTS:
- Do NOT include backend data fetching
- Focus only on UI presentation
- Use SF Symbols for icons
- Support Dark Mode automatically
- Do NOT modify any existing files
```

### Rewards View Component

```
Create a SwiftUI component for the child rewards view where children can redeem points for entertainment apps.

HIGH-LEVEL GOAL:
Design an engaging interface that makes reward redemption fun and clear for children while maintaining appropriate parental controls.

DETAILED INSTRUCTIONS:
1. Create a SwiftUI View named "RewardsView.swift"
2. Implement a tab-based child dashboard with "Dashboard", "Rewards", and "Profile" tabs
3. The Rewards tab should include:
   - Current points balance prominently displayed at top
   - Grid or list of available rewards (entertainment apps) with:
     * App icon
     * App name
     * Points cost
     * "Redeem" button (enabled only if child has enough points)
   - Recent redemptions history section
4. Use a playful, child-friendly design with:
   - Gold/yellow accents for rewards (#FFD700)
   - Rounded elements
   - Fun icons and visual feedback
5. Include animations for point spending and reward unlocking
6. Implement proper state management for points balance updates

VISUAL STYLE:
- Vibrant but not overwhelming color scheme
- Large, clear buttons for easy tapping
- Visual feedback for interactions
- Consistent with overall app design language

TECHNICAL CONSTRAINTS:
- Use SwiftUI only
- Do NOT include actual app unlocking logic
- Focus on UI presentation layer
- Support both iPhone and iPad layouts
- Implement proper accessibility
```

## Important Notes

1. All generated code will require careful human review, testing, and refinement to be considered production-ready.
2. These prompts are designed for iterative development - create one component at a time rather than attempting to generate the entire application at once.
3. Always verify that generated code follows Apple's Human Interface Guidelines and SwiftUI best practices.
4. Ensure proper accessibility support is included in all generated components.
5. Test generated components on multiple device sizes and in both light and dark modes.