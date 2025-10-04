# ActivityView Documentation

## Overview
Enhanced parent activity monitoring view that provides comprehensive analytics and insights into family screen time usage.

## Features

### 📊 **Activity Analytics**
- **Time Range Filters**: Day, Week, Month views
- **Child-Specific Filtering**: View data for individual children or all combined
- **Real-time Summary Cards**: Learning time, points earned, total screen time, goal progress

### 📈 **Visual Charts**
- **Educational vs Entertainment Usage**: Bar charts showing daily usage patterns
- **Interactive Charts**: Built with Swift Charts framework
- **Weekly Trend Analysis**: 7-day historical data visualization

### 📱 **Activity Feed**
- **Real-time Activity Tracking**: Shows recent app usage by child
- **Point Attribution**: Displays points earned for educational activities
- **Category Icons**: Visual distinction between educational and entertainment apps

### 🔗 **Analytics Integration**
- **Deep Analytics Access**: Sheet presentation of AnalyticsDashboardView
- **Export Capabilities**: Connect to comprehensive reporting features

## Technical Implementation

### Architecture
```swift
ActivityView: View
├── Filter Controls (TimeRange, Child Selection)
├── Summary Cards Grid (LazyVGrid)
├── Activity Feed (VStack of ActivityRow)
└── Analytics Integration (Sheet)
```

### Components
- **SummaryCard**: Reusable metric display component
- **ActivityRow**: Individual activity entry with child, app, duration, points
- **ActivityTimeRange**: Custom enum for time period filtering
- **DailyUsage**: Data model for usage statistics

### Data Flow
```
Sample Data → ActivityView State → UI Components → User Interaction → Analytics Dashboard
```

## Usage

### Parent Dashboard Integration
The ActivityView is integrated as the "Activity" tab in ParentMainView:

```swift
TabView {
    FamilyOverviewView()
        .tabItem { /* Family */ }

    ActivityView() // ← Enhanced activity monitoring
        .tabItem { /* Activity */ }

    ParentSettingsView()
        .tabItem { /* Settings */ }
}
```

### Key User Flows
1. **View Family Activity**: Parents can see recent learning and entertainment usage
2. **Filter by Child**: Focus on specific child's activity patterns
3. **Time Range Analysis**: Compare daily, weekly, monthly trends
4. **Deep Dive Analytics**: Tap "View Details" for comprehensive reporting

## Sample Data Structure
```swift
DailyUsage(
    date: Date(),
    educational: 65,    // minutes of educational app usage
    entertainment: 20,  // minutes of entertainment app usage
    points: 65         // points earned from educational usage
)
```

## Integration Points

### Dependencies
- `Charts`: For visual data representation
- `SharedModels`: For common data structures
- `AnalyticsDashboardView`: For detailed analytics

### Related Components
- **ChildMainView**: Shows child-side progress and activity
- **FamilyOverviewView**: Provides family-level dashboard
- **AnalyticsDashboardView**: Comprehensive analytics and reporting

## Future Enhancements
- Real-time data integration with DeviceActivity monitoring
- Push notifications for activity milestones
- Customizable goal setting per child
- Export functionality for activity reports
- Advanced filtering options (app categories, time of day)

## Testing
The ActivityView includes comprehensive preview support and integrates with existing test infrastructure for family dashboard functionality.