# Screen Time Rewards - Reward-Based Screen Time Management App

Screen Time Rewards helps parents create a positive relationship between their children and technology by rewarding productive screen time activities. Children earn points for educational app usage, reading, and creative activities, which can be redeemed for rewards set by parents.

This repository contains the complete codebase for the Screen Time Rewards iOS application, along with documentation, tests, and deployment configurations.

## Project Status

**Current Phase:** MVP Testing and Validation (v1.0)
**Status:** Core Features Complete, Testing In Progress

The project has successfully implemented all core MVP features. The team is now executing a comprehensive testing and validation phase to ensure quality before implementing premium subscription functionality.

## Completed Features

### ✅ Epic 1: Foundation & Core Infrastructure
- Project setup with Swift Package Manager
- iOS Family Controls and Screen Time API integration
- CloudKit setup with zone-based architecture
- iCloud authentication

### ✅ Epic 2: Core Reward System
- App categorization UI
- Point tracking engine
- Reward redemption UI

### ✅ Epic 3: User Experience & Interface
- Parent dashboard UI
- Child dashboard UI
- App categorization screen
- Settings screen

## In Progress Features

### 🔄 Testing and Validation
- **Unit Testing Enhancement**: Improving existing unit tests with edge cases and fixing identified test failures
- **Integration Testing**: Validating data layer and UI integration with CloudKit and Family Controls
- **End-to-End Testing**: Executing core user journeys and cross-device synchronization scenarios
- **Performance Validation**: Ensuring <5% battery impact and <100MB storage requirements
- **Security and Privacy Validation**: Maintaining COPPA compliance and data encryption
- **User Experience Refinement**: Polishing UI components and accessibility features

### 🔜 Premium Features (Post-MVP)
- Subscription management
- Multi-parent collaboration

## Repository Structure

```
.
├── ScreenTimeRewards/
│   ├── ScreenTimeRewards/           # Main iOS app
│   ├── Packages/                    # Swift packages
│   │   ├── RewardCore/              # Business logic
│   │   ├── CloudKitService/         # CloudKit integration
│   │   ├── FamilyControlsKit/       # Family Controls wrapper
│   │   ├── SubscriptionService/     # StoreKit 2 integration
│   │   ├── DesignSystem/            # Shared UI components
│   │   ├── SharedModels/            # Data models
│   │   └── AppIntents/              # Siri shortcuts
│   ├── Tests/                       # Test suite
│   └── Documentation/               # Project documentation
├── docs/                            # Project documentation
│   ├── stories/                     # User stories
│   ├── architecture/                # Architecture documentation
│   └── qa/                          # Quality assurance documentation
└── Configuration/                   # Project configuration
```

## Documentation

### Core Project Documents
- [Product Requirements Document](docs/prd.md)
- [Architecture Document](docs/architecture.md)
- [Backlog Prioritization](docs/backlog-prioritization.md)
- [Rollback Procedures](docs/rollback-procedures.md)

### Testing and Validation
- [Core Reward System Testing Plan](docs/core-reward-system-testing-plan.md)
- [Test Enhancement Plan](docs/test-enhancement-plan.md)
- [Core Reward System Validation Checklist](docs/core-reward-system-validation-checklist.md)

### Future Planning
- [Multi-Parent Implementation Plan](docs/multi-parent-implementation-plan.md)
- [v1.1 Preparation Plan](docs/v1.1-preparation-plan.md)

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 15.0+ device or simulator
- Apple ID for CloudKit testing

### Installation

1. Clone the repository
2. Open `ScreenTimeRewards/ScreenTimeRewards.xcodeproj` in Xcode
3. Select your development team in the project settings
4. Build and run the project

### Testing

Run unit tests using Xcode's test navigator or command line:

```bash
swift test
```

## Contributing

Please read [CONTRIBUTING.md](ScreenTimeRewards/Documentation/CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Team

- **Product Owner:** Sarah
- **Scrum Master:** Bob
- **Lead Developer:** James
- **QA Engineer:** Quinn

## Acknowledgments

- Thanks to Apple's Family Controls framework for enabling screen time management
- Inspired by positive reinforcement techniques in child development research