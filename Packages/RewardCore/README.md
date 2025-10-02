# RewardCore Package

The RewardCore package contains the core business logic for the ScreenTime Rewards application, including point tracking and calculation functionality.

## Components

### PointTrackingService
Responsible for tracking time spent in educational apps and coordinating point calculations. Integrates with DeviceActivityMonitor to track app usage and works with the calculation engine to determine points earned.

### PointCalculationEngine
Handles the calculation of points based on usage sessions. Takes into account app categories and parent-defined point values to determine the appropriate number of points to award.

### Repositories
- UsageSessionRepository: Manages persistence of usage session data
- PointTransactionRepository: Manages persistence of point transaction records

## Features

1. **Time Tracking**: Monitors time spent in categorized educational apps
2. **Point Calculation**: Calculates points based on parent-defined values
3. **Background Tracking**: Continues tracking even when the app is in the background
4. **Data Persistence**: Ensures tracking data survives app restarts
5. **Edge Case Handling**: Manages app switching, device sleep/wake cycles, and other edge cases

## Dependencies

- SharedModels: For data structures and protocols
- CloudKitService: For data persistence
- FamilyControlsKit: For integration with iOS Family Controls framework

## Testing

The package includes comprehensive unit tests for all core functionality:
- Point calculation accuracy
- Usage session processing
- Data persistence operations
- Edge case handling