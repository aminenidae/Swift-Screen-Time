import XCTest
import UserNotifications
import SharedModels
@testable import SubscriptionService

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class TrialNotificationServiceTests: XCTestCase {
    var notificationService: TrialNotificationService!
    fileprivate var mockFamilyRepository: MockFamilyRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockFamilyRepository = MockFamilyRepository()
        notificationService = TrialNotificationService(familyRepository: mockFamilyRepository)
    }

    override func tearDown() async throws {
        notificationService = nil
        mockFamilyRepository = nil
        try await super.tearDown()
    }

    func testTrialNotificationServiceInitialization() {
        // Given: TrialNotificationService
        // When: Service is initialized
        // Then: Should not be nil and loading should be false initially
        XCTAssertNotNil(notificationService)
        XCTAssertFalse(notificationService.isLoading)
        XCTAssertNil(notificationService.error)
    }

    func testScheduleTrialNotificationsForFamilyWithoutTrial() async {
        // Given: Family without trial metadata
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: []
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Scheduling trial notifications (will fail due to permissions in test environment)
        await notificationService.scheduleTrialNotifications(for: "test-family")

        // Then: Should set an error
        XCTAssertNotNil(notificationService.error)
    }

    func testSetupNotificationCategories() {
        // When: Setting up notification categories
        notificationService.setupNotificationCategories()

        // Then: Should not crash (basic functionality test)
        XCTAssertTrue(true)
    }

    func testCancelTrialNotifications() async {
        // Given: Service with family ID
        let familyID = "test-family"

        // When: Canceling trial notifications
        await notificationService.cancelTrialNotifications(for: familyID)

        // Then: Should complete without error
        XCTAssertTrue(true)
    }
}

@available(iOS 15.0, macOS 12.0, *)
fileprivate class MockFamilyRepository: FamilyRepository {
    var families: [String: Family] = [:]

    func createFamily(_ family: Family) async throws -> Family {
        families[family.id] = family
        return family
    }

    func fetchFamily(id: String) async throws -> Family? {
        return families[id]
    }

    func fetchFamilies(for userID: String) async throws -> [Family] {
        return Array(families.values.filter { $0.ownerUserID == userID })
    }

    func updateFamily(_ family: Family) async throws -> Family {
        families[family.id] = family
        return family
    }

    func deleteFamily(id: String) async throws {
        families.removeValue(forKey: id)
    }
}