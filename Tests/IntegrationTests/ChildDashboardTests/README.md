# Child Dashboard Integration Tests

This directory contains integration tests for the Child Dashboard feature.

## Test Coverage

The tests in this directory verify that all components of the Child Dashboard work together correctly:

1. **UI Component Integration**
   - ProgressRingView displays progress correctly
   - PointsBalanceView shows current points
   - RewardCardView displays available rewards
   - FloatingPointsNotificationView shows notifications

2. **Data Flow Integration**
   - ChildDashboardViewModel loads data properly
   - ChildDashboardView integrates all components
   - Real-time updates work correctly

3. **User Interaction Integration**
   - Reward redemption flow
   - Point earning notifications
   - Dashboard navigation

## Test Files

- `ChildDashboardIntegrationTests.swift` - Main integration tests for the Child Dashboard

## Running Tests

To run these tests, use Xcode's test navigator or the command line:

```bash
swift test --filter ChildDashboardIntegrationTests
```