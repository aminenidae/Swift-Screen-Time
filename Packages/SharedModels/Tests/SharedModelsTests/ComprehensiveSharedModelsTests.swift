import XCTest
@testable import SharedModels

final class ComprehensiveSharedModelsTests: XCTestCase {
    
    // MARK: - Family Tests
    
    func testFamilyInitialization() {
        let now = Date()
        let family = Family(
            id: "family-1",
            name: "Test Family",
            createdAt: now,
            ownerUserID: "user-1",
            sharedWithUserIDs: ["user-2", "user-3"],
            childProfileIDs: ["child-1", "child-2"],
            parentalConsentGiven: true,
            parentalConsentDate: now,
            parentalConsentMethod: "in-app"
        )
        
        XCTAssertEqual(family.id, "family-1")
        XCTAssertEqual(family.name, "Test Family")
        XCTAssertEqual(family.createdAt, now)
        XCTAssertEqual(family.ownerUserID, "user-1")
        XCTAssertEqual(family.sharedWithUserIDs, ["user-2", "user-3"])
        XCTAssertEqual(family.childProfileIDs, ["child-1", "child-2"])
        XCTAssertTrue(family.parentalConsentGiven)
        XCTAssertEqual(family.parentalConsentDate, now)
        XCTAssertEqual(family.parentalConsentMethod, "in-app")
    }
    
    func testFamilyCodable() throws {
        let now = Date()
        let family = Family(
            id: "family-1",
            name: "Test Family",
            createdAt: now,
            ownerUserID: "user-1",
            sharedWithUserIDs: ["user-2"],
            childProfileIDs: ["child-1"],
            parentalConsentGiven: true,
            parentalConsentDate: now,
            parentalConsentMethod: "in-app"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(family)
        let decoder = JSONDecoder()
        let decodedFamily = try decoder.decode(Family.self, from: data)
        
        XCTAssertEqual(family.id, decodedFamily.id)
        XCTAssertEqual(family.name, decodedFamily.name)
        XCTAssertEqual(family.createdAt.timeIntervalSince1970, decodedFamily.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(family.ownerUserID, decodedFamily.ownerUserID)
        XCTAssertEqual(family.sharedWithUserIDs, decodedFamily.sharedWithUserIDs)
        XCTAssertEqual(family.childProfileIDs, decodedFamily.childProfileIDs)
        XCTAssertEqual(family.parentalConsentGiven, decodedFamily.parentalConsentGiven)
        if let originalDate = family.parentalConsentDate, let decodedDate = decodedFamily.parentalConsentDate {
            XCTAssertEqual(originalDate.timeIntervalSince1970, decodedDate.timeIntervalSince1970, accuracy: 0.001)
        } else {
            XCTAssertNil(family.parentalConsentDate)
            XCTAssertNil(decodedFamily.parentalConsentDate)
        }
        XCTAssertEqual(family.parentalConsentMethod, decodedFamily.parentalConsentMethod)
    }
    
    // MARK: - ChildProfile Tests
    
    func testChildProfileInitialization() {
        let now = Date()
        let childProfile = ChildProfile(
            id: "child-1",
            familyID: "family-1",
            name: "Test Child",
            avatarAssetURL: "https://example.com/avatar.jpg",
            birthDate: now,
            pointBalance: 100,
            totalPointsEarned: 500,
            deviceID: "device-123",
            cloudKitZoneID: "zone-456",
            createdAt: now,
            ageVerified: true,
            verificationMethod: "parental-consent",
            dataRetentionPeriod: 365,
            notificationPreferences: NotificationPreferences()
        )
        
        XCTAssertEqual(childProfile.id, "child-1")
        XCTAssertEqual(childProfile.familyID, "family-1")
        XCTAssertEqual(childProfile.name, "Test Child")
        XCTAssertEqual(childProfile.avatarAssetURL, "https://example.com/avatar.jpg")
        XCTAssertEqual(childProfile.birthDate, now)
        XCTAssertEqual(childProfile.pointBalance, 100)
        XCTAssertEqual(childProfile.totalPointsEarned, 500)
        XCTAssertEqual(childProfile.deviceID, "device-123")
        XCTAssertEqual(childProfile.cloudKitZoneID, "zone-456")
        XCTAssertEqual(childProfile.createdAt, now)
        XCTAssertTrue(childProfile.ageVerified)
        XCTAssertEqual(childProfile.verificationMethod, "parental-consent")
        XCTAssertEqual(childProfile.dataRetentionPeriod, 365)
        XCTAssertNotNil(childProfile.notificationPreferences)
    }
    
    func testChildProfileCodable() throws {
        let now = Date()
        let childProfile = ChildProfile(
            id: "child-1",
            familyID: "family-1",
            name: "Test Child",
            avatarAssetURL: "https://example.com/avatar.jpg",
            birthDate: now,
            pointBalance: 100,
            totalPointsEarned: 500,
            deviceID: "device-123",
            cloudKitZoneID: "zone-456",
            createdAt: now,
            ageVerified: true,
            verificationMethod: "parental-consent",
            dataRetentionPeriod: 365,
            notificationPreferences: NotificationPreferences()
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(childProfile)
        let decoder = JSONDecoder()
        let decodedChildProfile = try decoder.decode(ChildProfile.self, from: data)
        
        XCTAssertEqual(childProfile.id, decodedChildProfile.id)
        XCTAssertEqual(childProfile.familyID, decodedChildProfile.familyID)
        XCTAssertEqual(childProfile.name, decodedChildProfile.name)
        XCTAssertEqual(childProfile.avatarAssetURL, decodedChildProfile.avatarAssetURL)
        XCTAssertEqual(childProfile.birthDate.timeIntervalSince1970, decodedChildProfile.birthDate.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(childProfile.pointBalance, decodedChildProfile.pointBalance)
        XCTAssertEqual(childProfile.totalPointsEarned, decodedChildProfile.totalPointsEarned)
        XCTAssertEqual(childProfile.deviceID, decodedChildProfile.deviceID)
        XCTAssertEqual(childProfile.cloudKitZoneID, decodedChildProfile.cloudKitZoneID)
        XCTAssertEqual(childProfile.createdAt.timeIntervalSince1970, decodedChildProfile.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(childProfile.ageVerified, decodedChildProfile.ageVerified)
        XCTAssertEqual(childProfile.verificationMethod, decodedChildProfile.verificationMethod)
        XCTAssertEqual(childProfile.dataRetentionPeriod, decodedChildProfile.dataRetentionPeriod)
        XCTAssertNotNil(decodedChildProfile.notificationPreferences)
    }
    
    // MARK: - AccountStatus Tests
    
    func testAccountStatusInitialization() {
        XCTAssertEqual(AccountStatus.available.rawValue, "available")
        XCTAssertEqual(AccountStatus.restricted.rawValue, "restricted")
        XCTAssertEqual(AccountStatus.noAccount.rawValue, "noAccount")
        XCTAssertEqual(AccountStatus.couldNotDetermine.rawValue, "couldNotDetermine")
    }
    
    func testAccountStatusCodable() throws {
        let status = AccountStatus.available
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(status)
        let decoder = JSONDecoder()
        let decodedStatus = try decoder.decode(AccountStatus.self, from: data)
        
        XCTAssertEqual(status, decodedStatus)
    }
    
    // MARK: - AuthState Tests
    
    func testAuthStateInitialization() {
        let authState = AuthState(
            isAuthenticated: true,
            accountStatus: .available,
            userID: "user-1",
            familyID: "family-1"
        )
        
        XCTAssertTrue(authState.isAuthenticated)
        XCTAssertEqual(authState.accountStatus, .available)
        XCTAssertEqual(authState.userID, "user-1")
        XCTAssertEqual(authState.familyID, "family-1")
    }
    
    func testAuthStateCodable() throws {
        let authState = AuthState(
            isAuthenticated: true,
            accountStatus: .available,
            userID: "user-1",
            familyID: "family-1"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(authState)
        let decoder = JSONDecoder()
        let decodedAuthState = try decoder.decode(AuthState.self, from: data)
        
        XCTAssertEqual(authState.isAuthenticated, decodedAuthState.isAuthenticated)
        XCTAssertEqual(authState.accountStatus, decodedAuthState.accountStatus)
        XCTAssertEqual(authState.userID, decodedAuthState.userID)
        XCTAssertEqual(authState.familyID, decodedAuthState.familyID)
    }
    
    // MARK: - AppCategory Tests
    
    func testAppCategoryInitialization() {
        XCTAssertEqual(AppCategory.learning.rawValue, "Learning")
        XCTAssertEqual(AppCategory.reward.rawValue, "Reward")
    }
    
    func testAppCategoryAllCases() {
        let allCases = AppCategory.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.learning))
        XCTAssertTrue(allCases.contains(.reward))
    }
    
    func testAppCategoryCodable() throws {
        let category = AppCategory.learning
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(category)
        let decoder = JSONDecoder()
        let decodedCategory = try decoder.decode(AppCategory.self, from: data)
        
        XCTAssertEqual(category, decodedCategory)
    }
    
    // MARK: - AppFilter Tests
    
    func testAppFilterAllCases() {
        let allCases = AppFilter.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.all))
        XCTAssertTrue(allCases.contains(.learning))
        XCTAssertTrue(allCases.contains(.reward))
    }
    
    func testAppFilterTitles() {
        XCTAssertEqual(AppFilter.all.title, "All")
        XCTAssertEqual(AppFilter.learning.title, "Learning")
        XCTAssertEqual(AppFilter.reward.title, "Reward")
    }
    
    // MARK: - AppMetadata Tests
    
    func testAppMetadataInitialization() {
        let iconData = Data("test-icon".utf8)
        let appMetadata = AppMetadata(
            id: "app-1",
            bundleID: "com.example.app",
            displayName: "Test App",
            isSystemApp: false,
            iconData: iconData
        )
        
        XCTAssertEqual(appMetadata.id, "app-1")
        XCTAssertEqual(appMetadata.bundleID, "com.example.app")
        XCTAssertEqual(appMetadata.displayName, "Test App")
        XCTAssertEqual(appMetadata.isSystemApp, false)
        XCTAssertEqual(appMetadata.iconData, iconData)
    }
    
    func testAppMetadataEquatable() {
        let iconData = Data("test-icon".utf8)
        let appMetadata1 = AppMetadata(
            id: "app-1",
            bundleID: "com.example.app",
            displayName: "Test App",
            isSystemApp: false,
            iconData: iconData
        )
        
        let appMetadata2 = AppMetadata(
            id: "app-1",
            bundleID: "com.example.app",
            displayName: "Test App",
            isSystemApp: false,
            iconData: iconData
        )
        
        let appMetadata3 = AppMetadata(
            id: "app-2",
            bundleID: "com.example.app2",
            displayName: "Test App 2",
            isSystemApp: true,
            iconData: nil
        )
        
        XCTAssertEqual(appMetadata1, appMetadata2)
        XCTAssertNotEqual(appMetadata1, appMetadata3)
    }
    
    func testAppMetadataCodable() throws {
        let iconData = Data("test-icon".utf8)
        let appMetadata = AppMetadata(
            id: "app-1",
            bundleID: "com.example.app",
            displayName: "Test App",
            isSystemApp: false,
            iconData: iconData
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(appMetadata)
        let decoder = JSONDecoder()
        let decodedAppMetadata = try decoder.decode(AppMetadata.self, from: data)
        
        XCTAssertEqual(appMetadata.id, decodedAppMetadata.id)
        XCTAssertEqual(appMetadata.bundleID, decodedAppMetadata.bundleID)
        XCTAssertEqual(appMetadata.displayName, decodedAppMetadata.displayName)
        XCTAssertEqual(appMetadata.isSystemApp, decodedAppMetadata.isSystemApp)
        XCTAssertEqual(appMetadata.iconData, decodedAppMetadata.iconData)
    }
    
    // MARK: - AppCategorization Tests
    
    func testAppCategorizationInitialization() {
        let now = Date()
        let appCategorization = AppCategorization(
            id: "cat-1",
            appBundleID: "com.example.app",
            category: .learning,
            childProfileID: "child-1",
            pointsPerHour: 20,
            createdAt: now,
            updatedAt: now
        )
        
        XCTAssertEqual(appCategorization.id, "cat-1")
        XCTAssertEqual(appCategorization.appBundleID, "com.example.app")
        XCTAssertEqual(appCategorization.category, .learning)
        XCTAssertEqual(appCategorization.childProfileID, "child-1")
        XCTAssertEqual(appCategorization.pointsPerHour, 20)
        XCTAssertEqual(appCategorization.createdAt, now)
        XCTAssertEqual(appCategorization.updatedAt, now)
    }
    
    func testAppCategorizationEquatable() {
        let now = Date()
        let appCategorization1 = AppCategorization(
            id: "cat-1",
            appBundleID: "com.example.app",
            category: .learning,
            childProfileID: "child-1",
            pointsPerHour: 20,
            createdAt: now,
            updatedAt: now
        )
        
        let appCategorization2 = AppCategorization(
            id: "cat-1",
            appBundleID: "com.example.app",
            category: .learning,
            childProfileID: "child-1",
            pointsPerHour: 20,
            createdAt: now,
            updatedAt: now
        )
        
        let appCategorization3 = AppCategorization(
            id: "cat-2",
            appBundleID: "com.example.app2",
            category: .reward,
            childProfileID: "child-2",
            pointsPerHour: 10,
            createdAt: now,
            updatedAt: now
        )
        
        XCTAssertEqual(appCategorization1, appCategorization2)
        XCTAssertNotEqual(appCategorization1, appCategorization3)
    }
    
    func testAppCategorizationCodable() throws {
        let now = Date()
        let appCategorization = AppCategorization(
            id: "cat-1",
            appBundleID: "com.example.app",
            category: .learning,
            childProfileID: "child-1",
            pointsPerHour: 20,
            createdAt: now,
            updatedAt: now
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(appCategorization)
        let decoder = JSONDecoder()
        let decodedAppCategorization = try decoder.decode(AppCategorization.self, from: data)
        
        XCTAssertEqual(appCategorization.id, decodedAppCategorization.id)
        XCTAssertEqual(appCategorization.appBundleID, decodedAppCategorization.appBundleID)
        XCTAssertEqual(appCategorization.category, decodedAppCategorization.category)
        XCTAssertEqual(appCategorization.childProfileID, decodedAppCategorization.childProfileID)
        XCTAssertEqual(appCategorization.pointsPerHour, decodedAppCategorization.pointsPerHour)
        XCTAssertEqual(appCategorization.createdAt.timeIntervalSince1970, decodedAppCategorization.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(appCategorization.updatedAt.timeIntervalSince1970, decodedAppCategorization.updatedAt.timeIntervalSince1970, accuracy: 0.001)
    }
    
    // MARK: - UsageSession Tests
    
    func testUsageSessionInitialization() {
        let now = Date()
        let endTime = now.addingTimeInterval(3600) // 1 hour later
        let usageSession = UsageSession(
            id: "session-1",
            childProfileID: "child-1",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: now,
            endTime: endTime,
            duration: 3600,
            isValidated: true
        )
        
        XCTAssertEqual(usageSession.id, "session-1")
        XCTAssertEqual(usageSession.childProfileID, "child-1")
        XCTAssertEqual(usageSession.appBundleID, "com.example.app")
        XCTAssertEqual(usageSession.category, .learning)
        XCTAssertEqual(usageSession.startTime, now)
        XCTAssertEqual(usageSession.endTime, endTime)
        XCTAssertEqual(usageSession.duration, 3600)
        XCTAssertTrue(usageSession.isValidated)
    }
    
    func testUsageSessionCodable() throws {
        let now = Date()
        let endTime = now.addingTimeInterval(3600) // 1 hour later
        let usageSession = UsageSession(
            id: "session-1",
            childProfileID: "child-1",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: now,
            endTime: endTime,
            duration: 3600,
            isValidated: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(usageSession)
        let decoder = JSONDecoder()
        let decodedUsageSession = try decoder.decode(UsageSession.self, from: data)
        
        XCTAssertEqual(usageSession.id, decodedUsageSession.id)
        XCTAssertEqual(usageSession.childProfileID, decodedUsageSession.childProfileID)
        XCTAssertEqual(usageSession.appBundleID, decodedUsageSession.appBundleID)
        XCTAssertEqual(usageSession.category, decodedUsageSession.category)
        XCTAssertEqual(usageSession.startTime.timeIntervalSince1970, decodedUsageSession.startTime.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(usageSession.endTime.timeIntervalSince1970, decodedUsageSession.endTime.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(usageSession.duration, decodedUsageSession.duration)
        XCTAssertEqual(usageSession.isValidated, decodedUsageSession.isValidated)
    }
    
    // MARK: - ScreenTimeSession Tests
    
    func testScreenTimeSessionInitialization() {
        let now = Date()
        let endTime = now.addingTimeInterval(3600) // 1 hour later
        let screenTimeSession = ScreenTimeSession(
            id: "session-1",
            childProfileID: "child-1",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: now,
            endTime: endTime,
            duration: 3600,
            pointsEarned: 20
        )
        
        XCTAssertEqual(screenTimeSession.id, "session-1")
        XCTAssertEqual(screenTimeSession.childProfileID, "child-1")
        XCTAssertEqual(screenTimeSession.appBundleID, "com.example.app")
        XCTAssertEqual(screenTimeSession.category, .learning)
        XCTAssertEqual(screenTimeSession.startTime, now)
        XCTAssertEqual(screenTimeSession.endTime, endTime)
        XCTAssertEqual(screenTimeSession.duration, 3600)
        XCTAssertEqual(screenTimeSession.pointsEarned, 20)
    }
    
    func testScreenTimeSessionCodable() throws {
        let now = Date()
        let endTime = now.addingTimeInterval(3600) // 1 hour later
        let screenTimeSession = ScreenTimeSession(
            id: "session-1",
            childProfileID: "child-1",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: now,
            endTime: endTime,
            duration: 3600,
            pointsEarned: 20
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(screenTimeSession)
        let decoder = JSONDecoder()
        let decodedScreenTimeSession = try decoder.decode(ScreenTimeSession.self, from: data)
        
        XCTAssertEqual(screenTimeSession.id, decodedScreenTimeSession.id)
        XCTAssertEqual(screenTimeSession.childProfileID, decodedScreenTimeSession.childProfileID)
        XCTAssertEqual(screenTimeSession.appBundleID, decodedScreenTimeSession.appBundleID)
        XCTAssertEqual(screenTimeSession.category, decodedScreenTimeSession.category)
        XCTAssertEqual(screenTimeSession.startTime.timeIntervalSince1970, decodedScreenTimeSession.startTime.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(screenTimeSession.endTime.timeIntervalSince1970, decodedScreenTimeSession.endTime.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(screenTimeSession.duration, decodedScreenTimeSession.duration)
        XCTAssertEqual(screenTimeSession.pointsEarned, decodedScreenTimeSession.pointsEarned)
    }
    
    // MARK: - Reward Tests
    
    func testRewardInitialization() {
        let now = Date()
        let reward = Reward(
            id: "reward-1",
            name: "Extra Screen Time",
            description: "30 minutes of extra screen time",
            pointCost: 100,
            imageURL: "https://example.com/reward.jpg",
            isActive: true,
            createdAt: now
        )
        
        XCTAssertEqual(reward.id, "reward-1")
        XCTAssertEqual(reward.name, "Extra Screen Time")
        XCTAssertEqual(reward.description, "30 minutes of extra screen time")
        XCTAssertEqual(reward.pointCost, 100)
        XCTAssertEqual(reward.imageURL, "https://example.com/reward.jpg")
        XCTAssertTrue(reward.isActive)
        XCTAssertEqual(reward.createdAt, now)
    }
    
    func testRewardCodable() throws {
        let now = Date()
        let reward = Reward(
            id: "reward-1",
            name: "Extra Screen Time",
            description: "30 minutes of extra screen time",
            pointCost: 100,
            imageURL: "https://example.com/reward.jpg",
            isActive: true,
            createdAt: now
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(reward)
        let decoder = JSONDecoder()
        let decodedReward = try decoder.decode(Reward.self, from: data)
        
        XCTAssertEqual(reward.id, decodedReward.id)
        XCTAssertEqual(reward.name, decodedReward.name)
        XCTAssertEqual(reward.description, decodedReward.description)
        XCTAssertEqual(reward.pointCost, decodedReward.pointCost)
        XCTAssertEqual(reward.imageURL, decodedReward.imageURL)
        XCTAssertEqual(reward.isActive, decodedReward.isActive)
        XCTAssertEqual(reward.createdAt.timeIntervalSince1970, decodedReward.createdAt.timeIntervalSince1970, accuracy: 0.001)
    }
    
    // MARK: - RedemptionValidationResult Tests
    
    func testRedemptionValidationResultCodable() throws {
        let validResult = RedemptionValidationResult.valid
        let insufficientPointsResult = RedemptionValidationResult.insufficientPoints(required: 100, available: 50)
        let rewardInactiveResult = RedemptionValidationResult.rewardInactive
        let otherErrorResult = RedemptionValidationResult.otherError("Test error")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test valid result
        let validData = try encoder.encode(validResult)
        let decodedValidResult = try decoder.decode(RedemptionValidationResult.self, from: validData)
        if case .valid = decodedValidResult {
            // Success
        } else {
            XCTFail("Expected valid result")
        }
        
        // Test insufficient points result
        let insufficientPointsData = try encoder.encode(insufficientPointsResult)
        let decodedInsufficientPointsResult = try decoder.decode(RedemptionValidationResult.self, from: insufficientPointsData)
        if case .insufficientPoints(let required, let available) = decodedInsufficientPointsResult {
            XCTAssertEqual(required, 100)
            XCTAssertEqual(available, 50)
        } else {
            XCTFail("Expected insufficient points result")
        }
        
        // Test reward inactive result
        let rewardInactiveData = try encoder.encode(rewardInactiveResult)
        let decodedRewardInactiveResult = try decoder.decode(RedemptionValidationResult.self, from: rewardInactiveData)
        if case .rewardInactive = decodedRewardInactiveResult {
            // Success
        } else {
            XCTFail("Expected reward inactive result")
        }
        
        // Test other error result
        let otherErrorData = try encoder.encode(otherErrorResult)
        let decodedOtherErrorResult = try decoder.decode(RedemptionValidationResult.self, from: otherErrorData)
        if case .otherError(let message) = decodedOtherErrorResult {
            XCTAssertEqual(message, "Test error")
        } else {
            XCTFail("Expected other error result")
        }
    }
    
    // MARK: - RedemptionResult Tests
    
    func testRedemptionResultCodable() throws {
        let successResult = RedemptionResult.success(transactionID: "tx-123")
        let failureResult = RedemptionResult.failure(reason: "Insufficient points")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test success result
        let successData = try encoder.encode(successResult)
        let decodedSuccessResult = try decoder.decode(RedemptionResult.self, from: successData)
        if case .success(let transactionID) = decodedSuccessResult {
            XCTAssertEqual(transactionID, "tx-123")
        } else {
            XCTFail("Expected success result")
        }
        
        // Test failure result
        let failureData = try encoder.encode(failureResult)
        let decodedFailureResult = try decoder.decode(RedemptionResult.self, from: failureData)
        if case .failure(let reason) = decodedFailureResult {
            XCTAssertEqual(reason, "Insufficient points")
        } else {
            XCTFail("Expected failure result")
        }
    }
    
    // MARK: - Achievement Tests
    
    func testAchievementInitialization() {
        let now = Date()
        let achievement = Achievement(
            id: "ach-1",
            name: "First Goal Completed",
            description: "Complete your first educational goal",
            criteria: "Complete any goal",
            pointReward: 50,
            imageURL: "https://example.com/achievement.jpg",
            isUnlocked: true,
            unlockedAt: now
        )
        
        XCTAssertEqual(achievement.id, "ach-1")
        XCTAssertEqual(achievement.name, "First Goal Completed")
        XCTAssertEqual(achievement.description, "Complete your first educational goal")
        XCTAssertEqual(achievement.criteria, "Complete any goal")
        XCTAssertEqual(achievement.pointReward, 50)
        XCTAssertEqual(achievement.imageURL, "https://example.com/achievement.jpg")
        XCTAssertTrue(achievement.isUnlocked)
        XCTAssertEqual(achievement.unlockedAt, now)
    }
    
    func testAchievementCodable() throws {
        let now = Date()
        let achievement = Achievement(
            id: "ach-1",
            name: "First Goal Completed",
            description: "Complete your first educational goal",
            criteria: "Complete any goal",
            pointReward: 50,
            imageURL: "https://example.com/achievement.jpg",
            isUnlocked: true,
            unlockedAt: now
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(achievement)
        let decoder = JSONDecoder()
        let decodedAchievement = try decoder.decode(Achievement.self, from: data)
        
        XCTAssertEqual(achievement.id, decodedAchievement.id)
        XCTAssertEqual(achievement.name, decodedAchievement.name)
        XCTAssertEqual(achievement.description, decodedAchievement.description)
        XCTAssertEqual(achievement.criteria, decodedAchievement.criteria)
        XCTAssertEqual(achievement.pointReward, decodedAchievement.pointReward)
        XCTAssertEqual(achievement.imageURL, decodedAchievement.imageURL)
        XCTAssertEqual(achievement.isUnlocked, decodedAchievement.isUnlocked)
        XCTAssertEqual(achievement.unlockedAt?.timeIntervalSince1970 ?? 0, decodedAchievement.unlockedAt?.timeIntervalSince1970 ?? 0, accuracy: 0.001)
    }
    
    // MARK: - PointTransaction Tests
    
    func testPointTransactionInitialization() {
        let now = Date()
        let transaction = PointTransaction(
            id: "tx-1",
            childProfileID: "child-1",
            points: 20,
            reason: "Completed learning session",
            timestamp: now
        )
        
        XCTAssertEqual(transaction.id, "tx-1")
        XCTAssertEqual(transaction.childProfileID, "child-1")
        XCTAssertEqual(transaction.points, 20)
        XCTAssertEqual(transaction.reason, "Completed learning session")
        XCTAssertEqual(transaction.timestamp, now)
    }
    
    func testPointTransactionCodable() throws {
        let now = Date()
        let transaction = PointTransaction(
            id: "tx-1",
            childProfileID: "child-1",
            points: 20,
            reason: "Completed learning session",
            timestamp: now
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(transaction)
        let decoder = JSONDecoder()
        let decodedTransaction = try decoder.decode(PointTransaction.self, from: data)
        
        XCTAssertEqual(transaction.id, decodedTransaction.id)
        XCTAssertEqual(transaction.childProfileID, decodedTransaction.childProfileID)
        XCTAssertEqual(transaction.points, decodedTransaction.points)
        XCTAssertEqual(transaction.reason, decodedTransaction.reason)
        XCTAssertEqual(transaction.timestamp.timeIntervalSince1970, decodedTransaction.timestamp.timeIntervalSince1970, accuracy: 0.001)
    }
    
    // MARK: - PointToTimeRedemption Tests
    
    func testPointToTimeRedemptionInitialization() {
        let now = Date()
        let expiresAt = now.addingTimeInterval(86400) // 24 hours later
        let redemption = PointToTimeRedemption(
            id: "redemption-1",
            childProfileID: "child-1",
            appCategorizationID: "cat-1",
            pointsSpent: 100,
            timeGrantedMinutes: 10,
            conversionRate: 10.0,
            redeemedAt: now,
            expiresAt: expiresAt,
            timeUsedMinutes: 5,
            status: .active
        )
        
        XCTAssertEqual(redemption.id, "redemption-1")
        XCTAssertEqual(redemption.childProfileID, "child-1")
        XCTAssertEqual(redemption.appCategorizationID, "cat-1")
        XCTAssertEqual(redemption.pointsSpent, 100)
        XCTAssertEqual(redemption.timeGrantedMinutes, 10)
        XCTAssertEqual(redemption.conversionRate, 10.0)
        XCTAssertEqual(redemption.redeemedAt, now)
        XCTAssertEqual(redemption.expiresAt, expiresAt)
        XCTAssertEqual(redemption.timeUsedMinutes, 5)
        XCTAssertEqual(redemption.status, .active)
    }
    
    func testPointToTimeRedemptionCodable() throws {
        let now = Date()
        let expiresAt = now.addingTimeInterval(86400) // 24 hours later
        let redemption = PointToTimeRedemption(
            id: "redemption-1",
            childProfileID: "child-1",
            appCategorizationID: "cat-1",
            pointsSpent: 100,
            timeGrantedMinutes: 10,
            conversionRate: 10.0,
            redeemedAt: now,
            expiresAt: expiresAt,
            timeUsedMinutes: 5,
            status: .active
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(redemption)
        let decoder = JSONDecoder()
        let decodedRedemption = try decoder.decode(PointToTimeRedemption.self, from: data)
        
        XCTAssertEqual(redemption.id, decodedRedemption.id)
        XCTAssertEqual(redemption.childProfileID, decodedRedemption.childProfileID)
        XCTAssertEqual(redemption.appCategorizationID, decodedRedemption.appCategorizationID)
        XCTAssertEqual(redemption.pointsSpent, decodedRedemption.pointsSpent)
        XCTAssertEqual(redemption.timeGrantedMinutes, decodedRedemption.timeGrantedMinutes)
        XCTAssertEqual(redemption.conversionRate, decodedRedemption.conversionRate)
        XCTAssertEqual(redemption.redeemedAt.timeIntervalSince1970, decodedRedemption.redeemedAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(redemption.expiresAt.timeIntervalSince1970, decodedRedemption.expiresAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(redemption.timeUsedMinutes, decodedRedemption.timeUsedMinutes)
        XCTAssertEqual(redemption.status, decodedRedemption.status)
    }
    
    // MARK: - RedemptionStatus Tests
    
    func testRedemptionStatusInitialization() {
        XCTAssertEqual(RedemptionStatus.active.rawValue, "active")
        XCTAssertEqual(RedemptionStatus.expired.rawValue, "expired")
        XCTAssertEqual(RedemptionStatus.used.rawValue, "used")
    }
    
    func testRedemptionStatusAllCases() {
        let allCases = RedemptionStatus.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.active))
        XCTAssertTrue(allCases.contains(.expired))
        XCTAssertTrue(allCases.contains(.used))
    }
    
    func testRedemptionStatusCodable() throws {
        let status = RedemptionStatus.active
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(status)
        let decoder = JSONDecoder()
        let decodedStatus = try decoder.decode(RedemptionStatus.self, from: data)
        
        XCTAssertEqual(status, decodedStatus)
    }
    
    // MARK: - RewardRedemption Tests
    
    func testRewardRedemptionInitialization() {
        let now = Date()
        let redemption = RewardRedemption(
            id: "redemption-1",
            childProfileID: "child-1",
            rewardID: "reward-1",
            pointsSpent: 100,
            timestamp: now,
            transactionID: "tx-123"
        )
        
        XCTAssertEqual(redemption.id, "redemption-1")
        XCTAssertEqual(redemption.childProfileID, "child-1")
        XCTAssertEqual(redemption.rewardID, "reward-1")
        XCTAssertEqual(redemption.pointsSpent, 100)
        XCTAssertEqual(redemption.timestamp, now)
        XCTAssertEqual(redemption.transactionID, "tx-123")
    }
    
    func testRewardRedemptionCodable() throws {
        let now = Date()
        let redemption = RewardRedemption(
            id: "redemption-1",
            childProfileID: "child-1",
            rewardID: "reward-1",
            pointsSpent: 100,
            timestamp: now,
            transactionID: "tx-123"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(redemption)
        let decoder = JSONDecoder()
        let decodedRedemption = try decoder.decode(RewardRedemption.self, from: data)
        
        XCTAssertEqual(redemption.id, decodedRedemption.id)
        XCTAssertEqual(redemption.childProfileID, decodedRedemption.childProfileID)
        XCTAssertEqual(redemption.rewardID, decodedRedemption.rewardID)
        XCTAssertEqual(redemption.pointsSpent, decodedRedemption.pointsSpent)
        XCTAssertEqual(redemption.timestamp.timeIntervalSince1970, decodedRedemption.timestamp.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(redemption.transactionID, decodedRedemption.transactionID)
    }
    
    // MARK: - FamilySettings Tests
    
    func testFamilySettingsInitialization() {
        let contentRestrictions: [String: Bool] = ["com.game.app": true, "com.social.app": false]
        let familySettings = FamilySettings(
            id: "settings-1",
            familyID: "family-1",
            dailyTimeLimit: 120,
            bedtimeStart: Date(),
            bedtimeEnd: Date().addingTimeInterval(3600),
            contentRestrictions: contentRestrictions
        )
        
        XCTAssertEqual(familySettings.id, "settings-1")
        XCTAssertEqual(familySettings.familyID, "family-1")
        XCTAssertEqual(familySettings.dailyTimeLimit, 120)
        XCTAssertNotNil(familySettings.bedtimeStart)
        XCTAssertNotNil(familySettings.bedtimeEnd)
        XCTAssertEqual(familySettings.contentRestrictions.count, 2)
        XCTAssertEqual(familySettings.contentRestrictions["com.game.app"], true)
        XCTAssertEqual(familySettings.contentRestrictions["com.social.app"], false)
    }
    
    func testFamilySettingsCodable() throws {
        let now = Date()
        let contentRestrictions: [String: Bool] = ["com.game.app": true, "com.social.app": false]
        let familySettings = FamilySettings(
            id: "settings-1",
            familyID: "family-1",
            dailyTimeLimit: 120,
            bedtimeStart: now,
            bedtimeEnd: now.addingTimeInterval(3600),
            contentRestrictions: contentRestrictions
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(familySettings)
        let decoder = JSONDecoder()
        let decodedFamilySettings = try decoder.decode(FamilySettings.self, from: data)
        
        XCTAssertEqual(familySettings.id, decodedFamilySettings.id)
        XCTAssertEqual(familySettings.familyID, decodedFamilySettings.familyID)
        XCTAssertEqual(familySettings.dailyTimeLimit, decodedFamilySettings.dailyTimeLimit)
        XCTAssertEqual(familySettings.bedtimeStart?.timeIntervalSince1970 ?? 0, decodedFamilySettings.bedtimeStart?.timeIntervalSince1970 ?? 0, accuracy: 0.001)
        XCTAssertEqual(familySettings.bedtimeEnd?.timeIntervalSince1970 ?? 0, decodedFamilySettings.bedtimeEnd?.timeIntervalSince1970 ?? 0, accuracy: 0.001)
        XCTAssertEqual(familySettings.contentRestrictions.count, decodedFamilySettings.contentRestrictions.count)
        XCTAssertEqual(familySettings.contentRestrictions["com.game.app"], decodedFamilySettings.contentRestrictions["com.game.app"])
        XCTAssertEqual(familySettings.contentRestrictions["com.social.app"], decodedFamilySettings.contentRestrictions["com.social.app"])
    }
    
    // MARK: - SubscriptionEntitlement Tests
    
    func testSubscriptionEntitlementInitialization() {
        let now = Date()
        let endDate = now.addingTimeInterval(31536000) // 1 year later
        let entitlement = SubscriptionEntitlement(
            id: "entitlement-1",
            familyID: "family-1",
            subscriptionTier: .oneChild,
            receiptData: "receipt-data-123",
            originalTransactionID: "orig-txn-123",
            transactionID: "txn-123",
            purchaseDate: now,
            expirationDate: endDate,
            isActive: true
        )
        
        XCTAssertEqual(entitlement.id, "entitlement-1")
        XCTAssertEqual(entitlement.familyID, "family-1")
        XCTAssertEqual(entitlement.subscriptionTier, .oneChild)
        XCTAssertEqual(entitlement.purchaseDate, now)
        XCTAssertEqual(entitlement.expirationDate, endDate)
        XCTAssertTrue(entitlement.isActive)
    }
    
    func testSubscriptionEntitlementCodable() throws {
        let now = Date()
        let endDate = now.addingTimeInterval(31536000) // 1 year later
        let entitlement = SubscriptionEntitlement(
            id: "entitlement-1",
            familyID: "family-1",
            subscriptionTier: .oneChild,
            receiptData: "receipt-data-123",
            originalTransactionID: "orig-txn-123",
            transactionID: "txn-123",
            purchaseDate: now,
            expirationDate: endDate,
            isActive: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(entitlement)
        let decoder = JSONDecoder()
        let decodedEntitlement = try decoder.decode(SubscriptionEntitlement.self, from: data)
        
        XCTAssertEqual(entitlement.id, decodedEntitlement.id)
        XCTAssertEqual(entitlement.familyID, decodedEntitlement.familyID)
        XCTAssertEqual(entitlement.subscriptionTier, decodedEntitlement.subscriptionTier)
        XCTAssertEqual(entitlement.purchaseDate.timeIntervalSince1970, decodedEntitlement.purchaseDate.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(entitlement.expirationDate.timeIntervalSince1970, decodedEntitlement.expirationDate.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(entitlement.isActive, decodedEntitlement.isActive)
    }
    
    // MARK: - GoalType Tests
    
    func testGoalTypeEquatable() {
        let timeBasedGoal1 = GoalType.timeBased(hours: 5)
        let timeBasedGoal2 = GoalType.timeBased(hours: 5)
        let timeBasedGoal3 = GoalType.timeBased(hours: 10)
        
        let pointBasedGoal1 = GoalType.pointBased(points: 100)
        let pointBasedGoal2 = GoalType.pointBased(points: 100)
        let pointBasedGoal3 = GoalType.pointBased(points: 200)
        
        let appSpecificGoal1 = GoalType.appSpecific(bundleID: "com.example.app", hours: 3)
        let appSpecificGoal2 = GoalType.appSpecific(bundleID: "com.example.app", hours: 3)
        let appSpecificGoal3 = GoalType.appSpecific(bundleID: "com.example.app2", hours: 3)
        
        let streakGoal1 = GoalType.streak(days: 7)
        let streakGoal2 = GoalType.streak(days: 7)
        let streakGoal3 = GoalType.streak(days: 14)
        
        XCTAssertEqual(timeBasedGoal1, timeBasedGoal2)
        XCTAssertNotEqual(timeBasedGoal1, timeBasedGoal3)
        
        XCTAssertEqual(pointBasedGoal1, pointBasedGoal2)
        XCTAssertNotEqual(pointBasedGoal1, pointBasedGoal3)
        
        XCTAssertEqual(appSpecificGoal1, appSpecificGoal2)
        XCTAssertNotEqual(appSpecificGoal1, appSpecificGoal3)
        
        XCTAssertEqual(streakGoal1, streakGoal2)
        XCTAssertNotEqual(streakGoal1, streakGoal3)
        
        XCTAssertNotEqual(timeBasedGoal1, pointBasedGoal1)
        XCTAssertNotEqual(pointBasedGoal1, appSpecificGoal1)
        XCTAssertNotEqual(appSpecificGoal1, streakGoal1)
    }
    
    func testGoalTypeCodable() throws {
        let timeBasedGoal = GoalType.timeBased(hours: 5)
        let pointBasedGoal = GoalType.pointBased(points: 100)
        let appSpecificGoal = GoalType.appSpecific(bundleID: "com.example.app", hours: 3)
        let streakGoal = GoalType.streak(days: 7)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test time based goal
        let timeBasedData = try encoder.encode(timeBasedGoal)
        let decodedTimeBasedGoal = try decoder.decode(GoalType.self, from: timeBasedData)
        if case .timeBased(let hours) = decodedTimeBasedGoal {
            XCTAssertEqual(hours, 5)
        } else {
            XCTFail("Expected time based goal")
        }
        
        // Test point based goal
        let pointBasedData = try encoder.encode(pointBasedGoal)
        let decodedPointBasedGoal = try decoder.decode(GoalType.self, from: pointBasedData)
        if case .pointBased(let points) = decodedPointBasedGoal {
            XCTAssertEqual(points, 100)
        } else {
            XCTFail("Expected point based goal")
        }
        
        // Test app specific goal
        let appSpecificData = try encoder.encode(appSpecificGoal)
        let decodedAppSpecificGoal = try decoder.decode(GoalType.self, from: appSpecificData)
        if case .appSpecific(let bundleID, let hours) = decodedAppSpecificGoal {
            XCTAssertEqual(bundleID, "com.example.app")
            XCTAssertEqual(hours, 3)
        } else {
            XCTFail("Expected app specific goal")
        }
        
        // Test streak goal
        let streakData = try encoder.encode(streakGoal)
        let decodedStreakGoal = try decoder.decode(GoalType.self, from: streakData)
        if case .streak(let days) = decodedStreakGoal {
            XCTAssertEqual(days, 7)
        } else {
            XCTFail("Expected streak goal")
        }
    }
    
    // MARK: - GoalFrequency Tests
    
    func testGoalFrequencyInitialization() {
        XCTAssertEqual(GoalFrequency.daily.rawValue, "daily")
        XCTAssertEqual(GoalFrequency.weekly.rawValue, "weekly")
        XCTAssertEqual(GoalFrequency.monthly.rawValue, "monthly")
        XCTAssertEqual(GoalFrequency.custom.rawValue, "custom")
    }
    
    func testGoalFrequencyCodable() throws {
        let frequency = GoalFrequency.weekly
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(frequency)
        let decoder = JSONDecoder()
        let decodedFrequency = try decoder.decode(GoalFrequency.self, from: data)
        
        XCTAssertEqual(frequency, decodedFrequency)
    }
}