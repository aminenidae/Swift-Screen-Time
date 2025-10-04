# Enhanced Reward System Documentation

## Overview
The reward system has been enhanced to include duration-based unlocking, making it more flexible and meaningful for both parents and children.

## Core Enhancement: Cost + Duration Model

### Before (Simple Cost)
```
YouTube Kids: 15 points → unlocked (indefinite time)
```

### After (Cost + Duration)
```
YouTube Kids: 15 points → 10 minutes (1.5 points/minute)
```

## New Reward System Structure

### Complete Flow
1. **Learning Phase**: Child uses learning apps to earn points
2. **Reward Phase**: Child spends points to unlock specific durations of reward apps
3. **Extension Phase**: Child can spend additional points to extend time using the same rate

### Example Scenarios

#### Scenario 1: YouTube Kids
- **Configuration**: 15 points = 10 minutes (1.5 pts/min)
- **Child Action**: Spends 15 points → Gets 10 minutes of YouTube
- **Extension**: Wants 5 more minutes → Spends 8 more points (1.5 × 5 = 7.5, rounded up)

#### Scenario 2: Minecraft
- **Configuration**: 30 points = 15 minutes (2.0 pts/min)
- **Child Action**: Spends 30 points → Gets 15 minutes of Minecraft
- **Extension**: Wants 10 more minutes → Spends 20 more points (2.0 × 10)

## Technical Implementation

### Enhanced Data Model
```swift
struct SimpleRewardApp: Identifiable {
    let id = UUID()
    var name: String
    var pointsCost: Int        // Points needed for base duration
    var baseDuration: Int      // Minutes unlocked for the cost
    var isEnabled: Bool

    // Calculated property for cost per minute
    var costPerMinute: Double {
        guard baseDuration > 0 else { return 0 }
        return Double(pointsCost) / Double(baseDuration)
    }
}
```

### Sample Data Configuration
```swift
[
    SimpleRewardApp(name: "YouTube Kids", pointsCost: 15, baseDuration: 10, isEnabled: true),
    SimpleRewardApp(name: "Minecraft", pointsCost: 30, baseDuration: 15, isEnabled: true),
    SimpleRewardApp(name: "Netflix", pointsCost: 20, baseDuration: 10, isEnabled: false),
    SimpleRewardApp(name: "Roblox", pointsCost: 25, baseDuration: 12, isEnabled: true),
    SimpleRewardApp(name: "TikTok", pointsCost: 10, baseDuration: 5, isEnabled: false)
]
```

## Parent Configuration Interface

### Enhanced Configuration Options
1. **Points Cost**: 5-100 points (adjustable in increments of 5)
2. **Base Duration**: 5-60 minutes (adjustable in increments of 5)
3. **Auto-calculated Rate**: Shows real-time points per minute

### Visual Feedback
- **Summary Line**: "★15 = 10min (1.5 pts/min)"
- **Rate Display**: Real-time calculation of cost per minute
- **Status Summary**: Shows cheapest entry point and best value options

### Configuration UI Features
```swift
// Expanded configuration when app is enabled
VStack(spacing: 8) {
    // Cost adjustment
    HStack {
        Text("Cost")
        Spacer()
        Button("-") { /* decrease cost */ }
        Text("★\(pointsCost)")
        Button("+") { /* increase cost */ }
    }

    // Duration adjustment
    HStack {
        Text("Duration")
        Spacer()
        Button("-") { /* decrease duration */ }
        Text("\(baseDuration) min")
        Button("+") { /* increase duration */ }
    }

    // Real-time rate calculation
    HStack {
        Text("Rate")
        Spacer()
        Text("\(costPerMinute, format: "%.1f") points per minute")
    }
}
```

## Status Dashboard

### Enhanced Metrics
1. **Available Apps**: Count of enabled reward apps
2. **Cheapest Entry**: Lowest cost to start any app + duration provided
3. **Best Value**: App with lowest cost per minute rate

### Example Status Display
```
Available Apps: 3
Cheapest Entry: ★10 (5min) - TikTok
Best Value: 1.5 pts/min - YouTube Kids
```

## Benefits of Enhanced System

### For Parents
1. **Granular Control**: Set specific time values for point costs
2. **Value Comparison**: Easy to see which apps offer better "value"
3. **Flexible Pricing**: Different apps can have different rates
4. **Clear Economics**: Transparent cost per minute for all apps

### For Children
1. **Clear Value**: Understand exactly what they're buying
2. **Choice Flexibility**: Can choose shorter sessions with fewer points
3. **Extension Options**: Can earn more points to extend favorite apps
4. **Budget Management**: Learn to manage limited points across options

### For the System
1. **Scalable Pricing**: Easy to adjust rates based on app desirability
2. **Usage Analytics**: Track actual time vs. cost ratios
3. **Behavioral Insights**: See which apps children value most
4. **Economic Balance**: Maintain learning incentive vs. reward balance

## Implementation Considerations

### Rate Calculation
- **Precision**: Uses Double for accurate calculations
- **Rounding**: UI rounds to 1 decimal place for clarity
- **Edge Cases**: Handles zero duration gracefully

### Extension Mechanism (Future)
The system is designed to support time extensions:
```swift
// Future implementation
func calculateExtensionCost(additionalMinutes: Int, app: SimpleRewardApp) -> Int {
    return Int(ceil(Double(additionalMinutes) * app.costPerMinute))
}
```

### Validation Rules
- **Minimum Cost**: 5 points (prevents too-easy unlocks)
- **Maximum Cost**: 100 points (prevents impossible unlocks)
- **Minimum Duration**: 5 minutes (meaningful time blocks)
- **Maximum Duration**: 60 minutes (prevents excessive sessions)

## Usage Examples

### Balanced Configuration
```
YouTube Kids: 15 pts = 10 min (1.5 pts/min) - Light entertainment
Minecraft:    30 pts = 15 min (2.0 pts/min) - Engaging but expensive
Educational Games: 10 pts = 15 min (0.67 pts/min) - Encourage learning
```

### High-Value Learning
```
Khan Academy: 20 pts = 30 min (0.67 pts/min) - Best value learning
Duolingo:     15 pts = 20 min (0.75 pts/min) - Language learning
YouTube:      30 pts = 10 min (3.0 pts/min)  - Expensive entertainment
```

## Future Enhancements

### Planned Features
1. **Dynamic Pricing**: Adjust rates based on usage patterns
2. **Time Banking**: Save unused minutes for later use
3. **Bundle Deals**: Multi-app packages at discounted rates
4. **Premium Time**: Higher cost for peak usage hours

### Analytics Integration
- Track cost-effectiveness of different pricing strategies
- Monitor learning time vs. reward time ratios
- Identify optimal pricing points for behavior modification

## Conclusion

The enhanced reward system provides a much more sophisticated and flexible approach to app access control. By introducing duration-based pricing, parents gain granular control while children learn valuable lessons about resource management and value comparison.

The system maintains the core simplicity of "earn points through learning, spend points for rewards" while adding the crucial dimension of time value that makes the economic model more realistic and educational.