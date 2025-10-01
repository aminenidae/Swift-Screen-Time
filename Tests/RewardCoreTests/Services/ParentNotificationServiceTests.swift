import XCTest
@testable import RewardCore
@testable import SharedModels
import UserNotifications

final class ParentNotificationServiceTests: XCTestCase {
    var notificationService: ParentNotificationService!
    var mockFamilyRepository: MockFamilyRepository!
    var mockNotificationCenter: MockNotificationCenter!
    
    override func setUp() {
        super.setUp()
        mockFamilyRepository = MockFamilyRepository()
        mockNotificationCenter = MockNotificationCenter()
        notificationService = ParentNotificationService(
            familyRepository: mockFamilyRepository,
            notificationCenter: mockNotificationCenter
        )
    }
    
    override func tearDown() {
        notificationService = nil
        mockFamilyRepository = nil
        mockNotificationCenter = nil
        super.tearDown()
    }

    private func createTestFamily(id: String) -> Family {
        return Family(
            id: id,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user-1",
            sharedWithUserIDs: [],
            childProfileIDs: ["child-1"],
            parentalConsentGiven: false,
            parentalConsentDate: nil,
            parentalConsentMethod: nil,
            subscriptionMetadata: nil
        )
    }
    
    func testNotifyParentsOfSuspiciousSession() async {
        // Create a suspicious validation result
        let validationResult = ValidationResult(
            isValid: false,
            validationScore: 0.3,
            confidenceLevel: 0.85, // Above threshold
            detectedPatterns: [.rapidAppSwitching(frequency: 10.0)],
            engagementMetrics: EngagementMetrics(
                appStateChanges: 15,
                averageSessionLength: 30,
                interactionDensity: 0.2,
                deviceMotionCorrelation: nil
            ),
            validationLevel: .strict,
            adjustmentFactor: 0.25
        )
        
        // Create a usage session
        let session = UsageSession(
            id: "test-session-1",
            childProfileID: "child-1",
            appBundleID: "com.example.learning",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800), // 30 minutes
            duration: 1800,
            isValidated: false,
            validationDetails: nil
        )
        
        // Set up mock family
        mockFamilyRepository.mockFamily = createTestFamily(id: "family-1")
        
        // Call the notification method
        await notificationService.notifyParents(of: validationResult, for: session, familyID: "family-1")
        
        // Verify notification was scheduled
        XCTAssertEqual(mockNotificationCenter.addedRequests.count, 1)
        let request = mockNotificationCenter.addedRequests.first
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.identifier, "suspicious-session-test-session-1")
        
        // Verify notification content
        let content = request?.content
        XCTAssertNotNil(content)
        XCTAssertEqual(content?.title, "Suspicious Usage Detected")
        XCTAssertNotNil(content?.body)
        XCTAssertNotNil(content?.userInfo["sessionID"] as? String)
        XCTAssertNotNil(content?.userInfo["validationScore"] as? Double)
        XCTAssertNotNil(content?.userInfo["confidenceLevel"] as? Double)
    }
    
    func testNotifyParentsBelowConfidenceThreshold() async {
        // Create a validation result below threshold
        let validationResult = ValidationResult(
            isValid: true,
            validationScore: 0.8,
            confidenceLevel: 0.7, // Below threshold
            detectedPatterns: [],
            engagementMetrics: EngagementMetrics(
                appStateChanges: 2,
                averageSessionLength: 1800,
                interactionDensity: 0.8,
                deviceMotionCorrelation: nil
            ),
            validationLevel: .moderate,
            adjustmentFactor: 1.0
        )
        
        // Create a usage session
        let session = UsageSession(
            id: "test-session-2",
            childProfileID: "child-1",
            appBundleID: "com.example.learning",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800), // 30 minutes
            duration: 1800,
            isValidated: false,
            validationDetails: nil
        )
        
        // Set up mock family
        mockFamilyRepository.mockFamily = createTestFamily(id: "family-1")
        
        // Call the notification method
        await notificationService.notifyParents(of: validationResult, for: session, familyID: "family-1")
        
        // Verify no notification was scheduled
        XCTAssertEqual(mockNotificationCenter.addedRequests.count, 0)
    }
    
    func testNotifyParentsWithNoFamily() async {
        // Create a suspicious validation result
        let validationResult = ValidationResult(
            isValid: false,
            validationScore: 0.3,
            confidenceLevel: 0.85, // Above threshold
            detectedPatterns: [.rapidAppSwitching(frequency: 10.0)],
            engagementMetrics: EngagementMetrics(
                appStateChanges: 15,
                averageSessionLength: 30,
                interactionDensity: 0.2,
                deviceMotionCorrelation: nil
            ),
            validationLevel: .strict,
            adjustmentFactor: 0.25
        )
        
        // Create a usage session
        let session = UsageSession(
            id: "test-session-3",
            childProfileID: "child-1",
            appBundleID: "com.example.learning",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800), // 30 minutes
            duration: 1800,
            isValidated: false,
            validationDetails: nil
        )
        
        // Don't set up mock family (simulate family not found)
        
        // Call the notification method
        await notificationService.notifyParents(of: validationResult, for: session, familyID: "family-1")
        
        // Verify no notification was scheduled
        XCTAssertEqual(mockNotificationCenter.addedRequests.count, 0)
    }
}

// Mock notification center for testing
class MockNotificationCenter: UNUserNotificationCenter {
    var addedRequests: [UNNotificationRequest] = []
    
    override func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }
    
    override func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        addedRequests.append(request)
        completionHandler?(nil)
    }
}

// Mock family repository for testing
class MockFamilyRepository: FamilyRepository {
    var mockFamily: Family?
    
    func createFamily(_ family: Family) async throws -> Family {
        return family
    }
    
    func fetchFamily(id: String) async throws -> Family? {
        return mockFamily
    }
    
    func updateFamily(_ family: Family) async throws -> Family {
        return family
    }
    
    func deleteFamily(id: String) async throws {
        // No-op for mock
    }
    
    func fetchFamilies(for userID: String) async throws -> [Family] {
        return mockFamily.map { [$0] } ?? []
    }
}