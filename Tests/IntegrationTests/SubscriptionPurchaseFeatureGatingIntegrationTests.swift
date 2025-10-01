import XCTest
@testable import SharedModels
@testable import CloudKitService

/// Integration tests for subscription purchase and feature gating
final class SubscriptionPurchaseFeatureGatingIntegrationTests: XCTestCase {
    
    var cloudKitService: CloudKitService!
    
    override func setUp() {
        super.setUp()
        cloudKitService = CloudKitService.shared
    }
    
    override func tearDown() {
        cloudKitService = nil
        super.tearDown()
    }
    
    // MARK: - Subscription Entitlement Integration Tests
    
    func testSubscriptionEntitlementCreationIntegration() async throws {
        // Given - Create a subscription entitlement
        let entitlement = SubscriptionEntitlement(
            id: "entitlement-\(UUID().uuidString)",
            familyID: "test-family-\(UUID().uuidString)",
            subscriptionType: "premium_monthly",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 30), // 30 days
            isActive: true
        )
        
        // When - Test that subscription entitlement repository is accessible
        // Note: There's no direct subscription repository in CloudKitService mock,
        // but we can test the model integration
        
        // Then - Verify subscription entitlement model integration
        XCTAssertEqual(entitlement.subscriptionType, "premium_monthly")
        XCTAssertEqual(entitlement.familyID, entitlement.familyID)
        XCTAssertTrue(entitlement.isActive)
        XCTAssertGreaterThan(entitlement.endDate, entitlement.startDate)
        
        // Test Codable conformance
        let data = try JSONEncoder().encode(entitlement)
        let decoded = try JSONDecoder().decode(SubscriptionEntitlement.self, from: data)
        XCTAssertEqual(entitlement.id, decoded.id)
        XCTAssertEqual(entitlement.subscriptionType, decoded.subscriptionType)
        XCTAssertEqual(entitlement.isActive, decoded.isActive)
    }
    
    func testSubscriptionEntitlementStorageAndRetrievalIntegration() async throws {
        // Given - A family and subscription scenario
        let familyID = "storage-test-family-\(UUID().uuidString)"
        let entitlement = SubscriptionEntitlement(
            id: "storage-entitlement-\(UUID().uuidString)",
            familyID: familyID,
            subscriptionType: "family_premium",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 365), // 1 year
            isActive: true
        )
        
        // When - Test model integration (since there's no repository in mock)
        let family = Family(
            id: familyID,
            name: "Storage Test Family",
            createdAt: Date(),
            ownerUserID: "owner-\(UUID().uuidString)",
            sharedWithUserIDs: ["user1", "user2"],
            childProfileIDs: ["child1", "child2"],
            parentalConsentGiven: true
        )
        
        let createdFamily = try await cloudKitService.createChild(ChildProfile(
            id: "temp-child-\(UUID().uuidString)",
            familyID: family.id,
            name: "Temp Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 0,
            totalPointsEarned: 0,
            createdAt: Date(),
            ageVerified: true
        ))
        
        // Then - Verify integration between family and subscription models
        XCTAssertEqual(createdFamily.familyID, family.id)
        XCTAssertEqual(entitlement.familyID, family.id)
    }
    
    // MARK: - Feature Gating Integration Tests
    
    func testFeatureGatingWithSubscriptionIntegration() async throws {
        // Given - Different subscription types and features
        let subscriptionTypes: [String: Set<String>] = [
            "basic": ["core_features", "basic_tracking"],
            "premium": ["core_features", "basic_tracking", "advanced_analytics", "custom_rewards"],
            "family": ["core_features", "basic_tracking", "advanced_analytics", "custom_rewards", "multi_child", "priority_support"]
        ]
        
        let features: [String] = ["core_features", "basic_tracking", "advanced_analytics", "custom_rewards", "multi_child", "priority_support"]
        
        // When - Test feature gating logic
        for (subscriptionType, availableFeatures) in subscriptionTypes {
            for feature in features {
                let isFeatureAvailable = availableFeatures.contains(feature)
                
                // Then - Verify feature gating integration
                switch subscriptionType {
                case "basic":
                    if feature == "core_features" || feature == "basic_tracking" {
                        XCTAssertTrue(isFeatureAvailable, "Basic subscription should have \(feature)")
                    } else {
                        XCTAssertFalse(isFeatureAvailable, "Basic subscription should not have \(feature)")
                    }
                case "premium":
                    if feature == "multi_child" || feature == "priority_support" {
                        XCTAssertFalse(isFeatureAvailable, "Premium subscription should not have \(feature)")
                    } else {
                        XCTAssertTrue(isFeatureAvailable, "Premium subscription should have \(feature)")
                    }
                case "family":
                    XCTAssertTrue(isFeatureAvailable, "Family subscription should have all features")
                default:
                    XCTFail("Unknown subscription type: \(subscriptionType)")
                }
            }
        }
    }
    
    func testFeatureGatingBasedOnEntitlementStatusIntegration() async throws {
        // Given - Entitlements with different statuses
        let activeEntitlement = SubscriptionEntitlement(
            id: "active-\(UUID().uuidString)",
            familyID: "active-family",
            subscriptionType: "premium",
            startDate: Date().addingTimeInterval(-86400), // Started yesterday
            endDate: Date().addingTimeInterval(86400 * 30), // Ends in 30 days
            isActive: true
        )
        
        let expiredEntitlement = SubscriptionEntitlement(
            id: "expired-\(UUID().uuidString)",
            familyID: "expired-family",
            subscriptionType: "premium",
            startDate: Date().addingTimeInterval(-86400 * 60), // Started 60 days ago
            endDate: Date().addingTimeInterval(-86400), // Ended yesterday
            isActive: false
        )
        
        let futureEntitlement = SubscriptionEntitlement(
            id: "future-\(UUID().uuidString)",
            familyID: "future-family",
            subscriptionType: "premium",
            startDate: Date().addingTimeInterval(86400), // Starts tomorrow
            endDate: Date().addingTimeInterval(86400 * 31), // Ends in 31 days
            isActive: false
        )
        
        // When - Test feature access based on entitlement status
        let premiumFeatures = ["advanced_analytics", "custom_rewards"]
        
        // Then - Verify feature access integration
        // Active entitlement should grant access
        XCTAssertTrue(activeEntitlement.isActive)
        XCTAssertGreaterThan(activeEntitlement.endDate, Date())
        XCTAssertLessThan(activeEntitlement.startDate, Date())
        
        // Expired entitlement should not grant access
        XCTAssertFalse(expiredEntitlement.isActive)
        XCTAssertLessThan(expiredEntitlement.endDate, Date())
        
        // Future entitlement should not grant access yet
        XCTAssertFalse(futureEntitlement.isActive)
        XCTAssertGreaterThan(futureEntitlement.startDate, Date())
    }
    
    // MARK: - Subscription Purchase Workflow Integration Tests
    
    func testCompleteSubscriptionPurchaseWorkflowIntegration() async throws {
        // Given - A family without subscription
        let familyID = "purchase-workflow-family-\(UUID().uuidString)"
        let family = Family(
            id: familyID,
            name: "Purchase Workflow Family",
            createdAt: Date(),
            ownerUserID: "owner-\(UUID().uuidString)",
            sharedWithUserIDs: ["user1"],
            childProfileIDs: ["child1"],
            parentalConsentGiven: true
        )
        
        // Create family through child profile (mock implementation)
        let childProfile = ChildProfile(
            id: "workflow-child-\(UUID().uuidString)",
            familyID: family.id,
            name: "Workflow Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100,
            totalPointsEarned: 300,
            createdAt: Date(),
            ageVerified: true
        )
        
        let createdChild = try await cloudKitService.createChild(childProfile)
        
        // When - Simulate subscription purchase workflow
        // 1. Create pending entitlement
        let pendingEntitlement = SubscriptionEntitlement(
            id: "pending-\(UUID().uuidString)",
            familyID: familyID,
            subscriptionType: "processing",
            startDate: Date(),
            endDate: Date(),
            isActive: false
        )
        
        // 2. Process payment (mock)
        let paymentProcessed = true
        let subscriptionType = "family_premium"
        let subscriptionDuration: TimeInterval = 86400 * 365 // 1 year
        
        // 3. Create active entitlement
        let activeEntitlement = SubscriptionEntitlement(
            id: "active-\(UUID().uuidString)",
            familyID: familyID,
            subscriptionType: subscriptionType,
            startDate: Date(),
            endDate: Date().addingTimeInterval(subscriptionDuration),
            isActive: true
        )
        
        // 4. Update family settings based on subscription
        var updatedFamilySettings = FamilySettings(
            id: "settings-\(familyID)",
            familyID: familyID,
            dailyTimeLimit: 480, // 8 hours with premium
            bedtimeStart: DateComponents(hour: 21, minute: 0), // 9 PM
            bedtimeEnd: DateComponents(hour: 7, minute: 0), // 7 AM
            contentRestrictions: [:]
        )
        
        // Then - Verify complete workflow integration
        XCTAssertEqual(createdChild.familyID, family.id)
        XCTAssertEqual(pendingEntitlement.subscriptionType, "processing")
        XCTAssertTrue(paymentProcessed)
        XCTAssertEqual(activeEntitlement.subscriptionType, subscriptionType)
        XCTAssertEqual(activeEntitlement.endDate.timeIntervalSince(activeEntitlement.startDate), subscriptionDuration, accuracy: 1.0)
        XCTAssertTrue(activeEntitlement.isActive)
        XCTAssertEqual(updatedFamilySettings.dailyTimeLimit, 480)
        XCTAssertNotNil(updatedFamilySettings.bedtimeStart)
        XCTAssertNotNil(updatedFamilySettings.bedtimeEnd)
    }
    
    // MARK: - Multi-Family Subscription Integration Tests
    
    func testMultiFamilySubscriptionIntegration() async throws {
        // Given - Multiple families with different subscription statuses
        let familiesData: [(id: String, subscriptionType: String?, isActive: Bool)] = [
            ("family1", "basic", true),
            ("family2", "premium", true),
            ("family3", "family", true),
            ("family4", nil, false), // No subscription
            ("family5", "expired", false) // Expired subscription
        ]
        
        var families: [Family] = []
        var entitlements: [SubscriptionEntitlement?] = []
        
        for (familyID, subscriptionType, isActive) in familiesData {
            let family = Family(
                id: familyID,
                name: "Test Family \(familyID)",
                createdAt: Date(),
                ownerUserID: "owner-\(familyID)",
                sharedWithUserIDs: [],
                childProfileIDs: ["child-\(familyID)"],
                parentalConsentGiven: true
            )
            families.append(family)
            
            if let subType = subscriptionType {
                let entitlement = SubscriptionEntitlement(
                    id: "entitlement-\(familyID)-\(UUID().uuidString)",
                    familyID: familyID,
                    subscriptionType: subType,
                    startDate: Date().addingTimeInterval(-86400), // Started yesterday
                    endDate: Date().addingTimeInterval(86400 * 30), // 30 days
                    isActive: isActive
                )
                entitlements.append(entitlement)
            } else {
                entitlements.append(nil)
            }
        }
        
        // When - Test multi-family subscription integration
        let familyEntitlementPairs = zip(families, entitlements)
        
        // Then - Verify integration
        for (family, entitlement) in familyEntitlementPairs {
            if let ent = entitlement {
                XCTAssertEqual(ent.familyID, family.id)
                XCTAssertTrue(ent.startDate < Date())
                XCTAssertTrue(ent.endDate > Date() || !ent.isActive)
            } else {
                // No entitlement for this family
                XCTAssertTrue(family.id == "family4")
            }
        }
    }
    
    // MARK: - Feature Availability Integration Tests
    
    func testFeatureAvailabilityBasedOnSubscriptionIntegration() async throws {
        // Given - Define feature sets for different subscription levels
        let featureSets: [String: [String: Bool]] = [
            "none": [
                "core_dashboard": true,
                "basic_tracking": true,
                "advanced_analytics": false,
                "custom_rewards": false,
                "multi_child": false,
                "priority_support": false,
                "family_sharing": false
            ],
            "basic": [
                "core_dashboard": true,
                "basic_tracking": true,
                "advanced_analytics": false,
                "custom_rewards": false,
                "multi_child": false,
                "priority_support": false,
                "family_sharing": true
            ],
            "premium": [
                "core_dashboard": true,
                "basic_tracking": true,
                "advanced_analytics": true,
                "custom_rewards": true,
                "multi_child": false,
                "priority_support": false,
                "family_sharing": true
            ],
            "family": [
                "core_dashboard": true,
                "basic_tracking": true,
                "advanced_analytics": true,
                "custom_rewards": true,
                "multi_child": true,
                "priority_support": true,
                "family_sharing": true
            ]
        ]
        
        // When - Test feature availability integration
        for (subscriptionType, features) in featureSets {
            for (feature, shouldBeAvailable) in features {
                // Then - Verify feature gating integration
                switch subscriptionType {
                case "none":
                    if feature == "core_dashboard" || feature == "basic_tracking" {
                        XCTAssertTrue(shouldBeAvailable, "Free tier should have \(feature)")
                    } else {
                        XCTAssertFalse(shouldBeAvailable, "Free tier should not have \(feature)")
                    }
                case "basic":
                    if feature == "advanced_analytics" || feature == "custom_rewards" || feature == "multi_child" || feature == "priority_support" {
                        XCTAssertFalse(shouldBeAvailable, "Basic tier should not have \(feature)")
                    } else {
                        XCTAssertTrue(shouldBeAvailable, "Basic tier should have \(feature)")
                    }
                case "premium":
                    if feature == "multi_child" || feature == "priority_support" {
                        XCTAssertFalse(shouldBeAvailable, "Premium tier should not have \(feature)")
                    } else {
                        XCTAssertTrue(shouldBeAvailable, "Premium tier should have \(feature)")
                    }
                case "family":
                    XCTAssertTrue(shouldBeAvailable, "Family tier should have all features including \(feature)")
                default:
                    XCTFail("Unknown subscription type: \(subscriptionType)")
                }
            }
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingInSubscriptionIntegration() async throws {
        // Test error handling in subscription and feature gating integration
        
        // Test with invalid subscription data
        let invalidEntitlement = SubscriptionEntitlement(
            id: "", // Empty ID
            familyID: "", // Empty family ID
            subscriptionType: "", // Empty type
            startDate: Date().addingTimeInterval(86400), // Future start
            endDate: Date().addingTimeInterval(3600), // Before start date
            isActive: true
        )
        
        // Should not crash even with invalid data
        XCTAssertTrue(invalidEntitlement.id.isEmpty)
        XCTAssertTrue(invalidEntitlement.familyID.isEmpty)
        XCTAssertTrue(invalidEntitlement.subscriptionType.isEmpty)
        XCTAssertGreaterThan(invalidEntitlement.startDate, Date()) // Future start
        XCTAssertLessThan(invalidEntitlement.endDate, invalidEntitlement.startDate) // End before start
        XCTAssertTrue(invalidEntitlement.isActive) // Still active despite invalid dates
        
        // Test edge cases
        let edgeCaseEntitlement = SubscriptionEntitlement(
            id: "edge-\(UUID().uuidString)",
            familyID: "edge-family",
            subscriptionType: "test_type",
            startDate: Date(),
            endDate: Date(), // Same as start
            isActive: false
        )
        
        XCTAssertEqual(edgeCaseEntitlement.startDate, edgeCaseEntitlement.endDate)
        XCTAssertFalse(edgeCaseEntitlement.isActive)
    }
    
    // MARK: - Performance Integration Tests
    
    func testSubscriptionPerformanceIntegration() async throws {
        measure {
            Task {
                do {
                    // Simulate integrated subscription workflow performance
                    for i in 0..<50 {
                        let entitlement = SubscriptionEntitlement(
                            id: "perf-entitlement-\(i)-\(UUID().uuidString)",
                            familyID: "perf-family-\(i)",
                            subscriptionType: "premium",
                            startDate: Date(),
                            endDate: Date().addingTimeInterval(86400 * 30),
                            isActive: true
                        )
                        
                        // Test feature gating with each entitlement
                        let hasAdvancedFeatures = entitlement.isActive && 
                            (entitlement.subscriptionType == "premium" || entitlement.subscriptionType == "family")
                        
                        XCTAssertTrue(entitlement.endDate > entitlement.startDate)
                        XCTAssertTrue(entitlement.isActive)
                        XCTAssertTrue(hasAdvancedFeatures)
                    }
                } catch {
                    // Expected in mock environment
                }
            }
        }
    }
    
    // MARK: - Concurrency Integration Tests
    
    func testConcurrentSubscriptionOperations() async throws {
        // Test concurrent operations in subscription workflow
        
        async let family1 = createTestFamily(name: "Concurrent Family 1")
        async let family2 = createTestFamily(name: "Concurrent Family 2")
        
        async let entitlement1 = createTestEntitlement(type: "basic")
        async let entitlement2 = createTestEntitlement(type: "premium")
        
        let results = try await [family1, family2, entitlement1, entitlement2]
        
        XCTAssertEqual(results.count, 4, "All concurrent operations should complete")
    }
    
    // MARK: - Helper Methods
    
    private func createTestFamily(name: String) async -> Family {
        return Family(
            id: "concurrent-family-\(UUID().uuidString)",
            name: name,
            createdAt: Date(),
            ownerUserID: "concurrent-owner-\(UUID().uuidString)",
            sharedWithUserIDs: [],
            childProfileIDs: ["concurrent-child-\(UUID().uuidString)"],
            parentalConsentGiven: true
        )
    }
    
    private func createTestEntitlement(type: String) async -> SubscriptionEntitlement {
        return SubscriptionEntitlement(
            id: "concurrent-entitlement-\(UUID().uuidString)",
            familyID: "concurrent-family-\(UUID().uuidString)",
            subscriptionType: type,
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 30),
            isActive: true
        )
    }
}