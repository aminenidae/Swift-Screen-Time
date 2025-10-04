# AI Prompt for Screen Time Rewards Settings UI Components

## Project Context

Screen Time Rewards is an iOS application built with Swift/SwiftUI that helps parents create a positive relationship between their children and technology by rewarding productive screen time activities. Children earn points for educational app usage, reading, and creative activities, which can be redeemed for rewards set by parents.

This prompt focuses specifically on generating or improving the Settings UI components for the parent dashboard.

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
You are an expert iOS SwiftUI developer tasked with creating UI components for the Settings section of a family screen time management application called "Screen Time Rewards". 

HIGH-LEVEL GOAL:
Create a well-organized, accessible, and visually appealing SwiftUI component for the Parent Settings that allows parents to configure all aspects of the app's functionality.

DETAILED INSTRUCTIONS:
1. Create a new SwiftUI View file named "ParentSettingsView.swift"
2. Implement a settings interface with the following sections:
   - General Settings (Family Setup, Family Controls, Family Members, Subscription)
   - Reward System (Learning App Points)
   - Child Settings (App Categories, Learning Apps, Reward Apps, Daily Time Limits, Special Rewards, Detailed Reports, Usage Trends)
   - Account (Switch to Child Profile, Reset App)
3. Each setting should follow these design principles:
   - Clear section headers with appropriate icons
   - Descriptive text explaining each setting's purpose
   - Appropriate controls (toggles, sliders, pickers, steppers) for different setting types
   - Visual feedback when settings are changed
   - Child selection mechanism for child-specific settings
4. Use a clean, modern design with:
   - Rounded corners (12pt radius for cards, 8pt for smaller elements)
   - Consistent spacing (8px grid)
   - Blue primary color (#4A90E2) with appropriate accent colors
   - Clear typography hierarchy
5. Ensure the design is responsive and works on different iOS device sizes
6. Implement proper accessibility support with labels and hints
7. Use SF Symbols for icons where appropriate
8. Include appropriate loading states and error handling

CODE EXAMPLES AND CONSTRAINTS:
- Follow Apple's Human Interface Guidelines
- Use SwiftUI best practices (State, Binding, ObservableObject)
- Structure code with clear separation of concerns
- Use List or Form for settings organization
- Implement proper error handling for data loading
- Do NOT use UIKit - this is a pure SwiftUI project
- Do NOT include backend logic - focus only on UI components

STRICT SCOPE:
Create only the ParentSettingsView.swift component and any supporting view models or helper structs needed for this view. Do not modify any existing files or create additional views beyond what's needed for this component.

MOBILE-FIRST APPROACH:
Design for iPhone first, then consider how the layout should adapt for iPad. Use size classes appropriately for responsive design.
```

## Component-Specific Prompts

### Child Selection Component

```
Create a reusable SwiftUI component for selecting which child's settings to configure in the Screen Time Rewards app.

HIGH-LEVEL GOAL:
Design an intuitive child selection interface that clearly shows available children and their status.

DETAILED INSTRUCTIONS:
1. Create a SwiftUI View named "ChildSelectionView.swift"
2. The component should display:
   - A header explaining the purpose of child selection
   - A list of family members who are children
   - Visual indicators for each child's status (app installed, online/offline)
   - Clear call-to-action for when no children are found
3. Include proper error handling for:
   - No family members found
   - Family sharing not set up
   - Network connectivity issues
4. Use a clean, modern design with:
   - Rounded corners (12pt radius)
   - Consistent spacing (8px grid)
   - Appropriate colors for different statuses
   - SF Symbols for icons
5. Ensure the design is responsive and works on different iOS device sizes
6. Implement proper accessibility support with labels and hints

VISUAL STYLE:
- Card-based layout for each child
- Green indicators for children with app installed
- Orange indicators for children needing app installation
- Clear visual hierarchy with child name prominent
- Appropriate touch targets (minimum 44x44 points)

CONSTRAINTS:
- Do NOT include backend data fetching
- Focus only on UI presentation
- Use SF Symbols for icons
- Support Dark Mode automatically
- Do NOT modify any existing files
```

### Settings Group Component

```
Create a reusable SwiftUI component for organizing related settings in the Screen Time Rewards app.

HIGH-LEVEL GOAL:
Design a flexible settings group component that can be collapsed/expanded and clearly organizes related settings.

DETAILED INSTRUCTIONS:
1. Create a SwiftUI View named "SettingsGroupView.swift"
2. The component should display:
   - A header with title and optional description
   - Expand/collapse functionality
   - Content area for settings controls
   - Visual indicator of expanded/collapsed state
3. Include proper accessibility support:
   - VoiceOver announcements for expand/collapse state
   - Proper heading hierarchy
   - Clear labels for all interactive elements
4. Use a clean, modern design with:
   - Rounded corners (12pt radius)
   - Subtle shadows for depth
   - Consistent spacing (8px grid)
   - Appropriate colors for background (#E6F7FF)
5. Ensure the design is responsive and works on different iOS device sizes

VISUAL STYLE:
- Light blue background for settings groups (#E6F7FF)
- Chevron icon to indicate expand/collapse state
- Smooth animation for expanding/collapsing
- Clear visual separation between groups

CONSTRAINTS:
- Do NOT include backend logic
- Focus only on UI presentation
- Support Dark Mode automatically
- Do NOT modify any existing files
```

### Numeric Setting Component

```
Create a reusable SwiftUI component for numeric settings with both slider and direct input in the Screen Time Rewards app.

HIGH-LEVEL GOAL:
Design a flexible numeric input component that allows precise control with both slider and direct input methods.

DETAILED INSTRUCTIONS:
1. Create a SwiftUI View named "NumericSettingView.swift"
2. The component should display:
   - Setting title and optional description
   - Slider control for approximate adjustments
   - Direct input field for precise values
   - Current value display
   - Appropriate units (minutes, points, etc.)
3. Include proper validation:
   - Minimum and maximum value constraints
   - Whole number enforcement for point values
   - Appropriate step values for different settings
4. Use a clean, modern design with:
   - Consistent spacing (8px grid)
   - Clear typography hierarchy
   - Appropriate colors for active/inactive states
   - SF Symbols for any icons
5. Ensure the design is responsive and works on different iOS device sizes
6. Implement proper accessibility support with labels and hints

VISUAL STYLE:
- Slider with appropriate tint color
- Direct input field with clear border
- Value display with appropriate formatting
- Smooth transitions when values change
- Clear visual feedback for active controls

CONSTRAINTS:
- Do NOT include backend logic
- Focus only on UI presentation
- Support Dark Mode automatically
- Do NOT modify any existing files
```

### Toggle with Confirmation Component

```
Create a reusable SwiftUI component for important toggle settings that require confirmation in the Screen Time Rewards app.

HIGH-LEVEL GOAL:
Design a toggle component that prevents accidental changes to important settings while maintaining ease of use.

DETAILED INSTRUCTIONS:
1. Create a SwiftUI View named "ConfirmationToggleView.swift"
2. The component should display:
   - Setting title and description
   - Toggle control in off/on states
   - Confirmation dialog for enabling certain settings
   - Visual feedback for the current state
3. Include proper state management:
   - Immediate visual feedback for toggle changes
   - Confirmation dialog for high-impact settings
   - Cancel/confirm options in dialogs
4. Use a clean, modern design with:
   - Consistent spacing (8px grid)
   - Clear typography hierarchy
   - Appropriate colors for different states
   - SF Symbols for any icons
5. Ensure the design is responsive and works on different iOS device sizes
6. Implement proper accessibility support with labels and hints

VISUAL STYLE:
- Standard iOS toggle for basic settings
- Custom toggle with confirmation for high-impact settings
- Clear visual distinction between on/off states
- Modal confirmation dialog with clear messaging
- Appropriate animations for state changes

CONSTRAINTS:
- Do NOT include backend logic
- Focus only on UI presentation
- Support Dark Mode automatically
- Do NOT modify any existing files
```

## Important Notes

1. All generated code will require careful human review, testing, and refinement to be considered production-ready.
2. These prompts are designed for iterative development - create one component at a time rather than attempting to generate the entire application at once.
3. Always verify that generated code follows Apple's Human Interface Guidelines and SwiftUI best practices.
4. Ensure proper accessibility support is included in all generated components.
5. Test generated components on multiple device sizes and in both light and dark modes.
6. Pay special attention to child-specific settings that require selection of a particular child before configuration.
7. Consider the hierarchical nature of settings where some settings may be dependent on others.
8. Ensure that all settings components provide clear feedback when values are changed or saved.