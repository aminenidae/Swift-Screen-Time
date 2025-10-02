import XCTest
@testable import RewardCore
import SharedModels

final class PointRedemptionServiceTests: XCTestCase {
    var pointRedemptionService: PointRedemptionService!
    var mockChildProfileRepository: MockChildProfileRepository!
    var mockPointToTimeRedemptionRepository: MockPointToTimeRedemptionRepository!
    var mockPointTransactionRepository: MockPointTransactionRepository!
    var mockAppCategorizationRepository: MockAppCategorizationRepository!

    override func setUp() {
        super.setUp()
        mockChildProfileRepository = MockChildProfileRepository()
        mockPointToTimeRedemptionRepository = MockPointToTimeRedemptionRepository()
        mockPointTransactionRepository = MockPointTransactionRepository()
        mockAppCategorizationRepository = MockAppCategorizationRepository()

        pointRedemptionService = PointRedemptionService(
            childProfileRepository: mockChildProfileRepository,
            pointToTimeRedemptionRepository: mockPointToTimeRedemptionRepository,
            pointTransactionRepository: mockPointTransactionRepository,
            appCategorizationRepository: mockAppCategorizationRepository
        )
    }

    override func tearDown() {
        pointRedemptionService = nil
        mockChildProfileRepository = nil
        mockPointToTimeRedemptionRepository = nil
        mockPointTransactionRepository = nil
        mockAppCategorizationRepository = nil
        super.tearDown()
    }

    // MARK: - Conversion Rate Tests

    func testGetConversionRate_RewardApp() {
        // Given
        let appCategorization = AppCategorization(
            id: "1",
            appBundleID: "com.game.app",
            category: .reward,
            childProfileID: "child-1",
            pointsPerHour: 120
        )

        // When
        let conversionRate = pointRedemptionService.getConversionRate(for: appCategorization)

        // Then
        XCTAssertEqual(conversionRate, 10.0) // Default rate: 10 points = 1 minute
    }

    // MARK: - Time Calculation Tests

    func testCalculateTimeMinutes_ValidConversion() {
        // Given
        let points = 60
        let conversionRate = 10.0

        // When
        let timeMinutes = pointRedemptionService.calculateTimeMinutes(points: points, conversionRate: conversionRate)

        // Then
        XCTAssertEqual(timeMinutes, 6) // 60 points / 10 = 6 minutes
    }

    func testCalculateRequiredPoints_ValidConversion() {
        // Given
        let timeMinutes = 5
        let conversionRate = 10.0

        // When
        let requiredPoints = pointRedemptionService.calculateRequiredPoints(timeMinutes: timeMinutes, conversionRate: conversionRate)

        // Then
        XCTAssertEqual(requiredPoints, 50) // 5 minutes * 10 = 50 points
    }

    // MARK: - Validation Tests

    func testValidateRedemption_Valid() async throws {
        // Given
        let childProfile = ChildProfile(
            id: "child-1",
            familyID: "family-1",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100
        )
        let appCategorization = AppCategorization(
            id: "app-1",
            appBundleID: "com.game.app",
            category: .reward,
            childProfileID: "child-1",
            pointsPerHour: 120
        )

        mockChildProfileRepository.mockChild = childProfile
        mockAppCategorizationRepository.mockCategorization = appCategorization
        mockPointToTimeRedemptionRepository.mockRedemptions = []

        // When
        let result = try await pointRedemptionService.validateRedemption(
            childID: "child-1",
            appCategorizationID: "app-1",
            pointsToSpend: 50
        )

        // Then
        XCTAssertTrue(result.isValid)
    }

    func testValidateRedemption_InsufficientPoints() async throws {
        // Given
        let childProfile = ChildProfile(
            id: "child-1",
            familyID: "family-1",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 30 // Less than required 50
        )

        mockChildProfileRepository.mockChild = childProfile

        // When
        let result = try await pointRedemptionService.validateRedemption(
            childID: "child-1",
            appCategorizationID: "app-1",
            pointsToSpend: 50
        )

        // Then
        if case .insufficientPoints(let required, let available) = result {
            XCTAssertEqual(required, 50)
            XCTAssertEqual(available, 30)
        } else {
            XCTFail("Expected insufficientPoints result")
        }
    }

    func testValidateRedemption_AppNotFound() async throws {
        // Given
        let childProfile = ChildProfile(
            id: "child-1",
            familyID: "family-1",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100
        )

        mockChildProfileRepository.mockChild = childProfile
        mockAppCategorizationRepository.mockCategorization = nil // App not found

        // When
        let result = try await pointRedemptionService.validateRedemption(
            childID: "child-1",
            appCategorizationID: "non-existent-app",
            pointsToSpend: 50
        )

        // Then
        if case .appNotFound = result {
            // Success
        } else {
            XCTFail("Expected appNotFound result")
        }
    }

    func testValidateRedemption_TimeLimitExceeded() async throws {
        // Given
        let childProfile = ChildProfile(
            id: "child-1",
            familyID: "family-1",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 2000 // Enough points
        )
        let appCategorization = AppCategorization(
            id: "app-1",
            appBundleID: "com.game.app",
            category: .reward,
            childProfileID: "child-1",
            pointsPerHour: 120
        )

        // Mock existing active redemptions that would exceed daily limit
        let existingRedemption = PointToTimeRedemption(
            id: "existing-1",
            childProfileID: "child-1",
            appCategorizationID: "app-1",
            pointsSpent: 1700,
            timeGrantedMinutes: 170, // Already has 170 minutes
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            timeUsedMinutes: 0,
            status: .active
        )

        mockChildProfileRepository.mockChild = childProfile
        mockAppCategorizationRepository.mockCategorization = appCategorization
        mockPointToTimeRedemptionRepository.mockRedemptions = [existingRedemption]

        // When (trying to add 20 more minutes, total would be 190 > 180 limit)
        let result = try await pointRedemptionService.validateRedemption(
            childID: "child-1",
            appCategorizationID: "app-1",
            pointsToSpend: 200 // 20 minutes
        )

        // Then
        if case .timeLimitExceeded = result {
            // Success
        } else {
            XCTFail("Expected timeLimitExceeded result, got \(result)")
        }
    }

    // MARK: - Redemption Tests

    func testRedeemPointsForScreenTime_Success() async throws {
        // Given
        let childProfile = ChildProfile(
            id: "child-1",
            familyID: "family-1",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100
        )
        let appCategorization = AppCategorization(
            id: "app-1",
            appBundleID: "com.game.app",
            category: .reward,
            childProfileID: "child-1",
            pointsPerHour: 120
        )

        mockChildProfileRepository.mockChild = childProfile
        mockAppCategorizationRepository.mockCategorization = appCategorization
        mockPointToTimeRedemptionRepository.mockRedemptions = []

        // When
        let result = try await pointRedemptionService.redeemPointsForScreenTime(
            childID: "child-1",
            appCategorizationID: "app-1",
            pointsToSpend: 50
        )

        // Then
        if case .success(let redemptionID) = result {
            XCTAssertFalse(redemptionID.isEmpty)
            // Verify repositories were called
            XCTAssertEqual(mockPointToTimeRedemptionRepository.createdRedemptions.count, 1)
            XCTAssertEqual(mockPointTransactionRepository.createdTransactions.count, 1)
            XCTAssertEqual(mockChildProfileRepository.updatedChildren.count, 1)

            // Verify redemption details
            let createdRedemption = mockPointToTimeRedemptionRepository.createdRedemptions.first!
            XCTAssertEqual(createdRedemption.pointsSpent, 50)
            XCTAssertEqual(createdRedemption.timeGrantedMinutes, 5) // 50 / 10 = 5 minutes

            // Verify transaction
            let createdTransaction = mockPointTransactionRepository.createdTransactions.first!
            XCTAssertEqual(createdTransaction.points, -50)

            // Verify child balance update
            let updatedChild = mockChildProfileRepository.updatedChildren.first!
            XCTAssertEqual(updatedChild.pointBalance, 50) // 100 - 50 = 50
        } else {
            XCTFail("Expected success result")
        }
    }

    func testRedeemPointsForScreenTime_InsufficientPoints() async throws {
        // Given
        let childProfile = ChildProfile(
            id: "child-1",
            familyID: "family-1",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 30
        )

        mockChildProfileRepository.mockChild = childProfile

        // When
        let result = try await pointRedemptionService.redeemPointsForScreenTime(
            childID: "child-1",
            appCategorizationID: "app-1",
            pointsToSpend: 50
        )

        // Then
        if case .insufficientPoints(let required, let available) = result {
            XCTAssertEqual(required, 50)
            XCTAssertEqual(available, 30)
            // Verify no repositories were called
            XCTAssertTrue(mockPointToTimeRedemptionRepository.createdRedemptions.isEmpty)
            XCTAssertTrue(mockPointTransactionRepository.createdTransactions.isEmpty)
            XCTAssertTrue(mockChildProfileRepository.updatedChildren.isEmpty)
        } else {
            XCTFail("Expected insufficientPoints result")
        }
    }

    // MARK: - Active Redemptions Tests

    func testGetActiveRedemptions_FiltersByStatusAndExpiry() async throws {
        // Given
        let now = Date()
        let activeRedemption = PointToTimeRedemption(
            id: "active-1",
            childProfileID: "child-1",
            appCategorizationID: "app-1",
            pointsSpent: 50,
            timeGrantedMinutes: 5,
            conversionRate: 10.0,
            redeemedAt: now,
            expiresAt: now.addingTimeInterval(3600), // Expires in 1 hour
            timeUsedMinutes: 0,
            status: .active
        )
        let expiredRedemption = PointToTimeRedemption(
            id: "expired-1",
            childProfileID: "child-1",
            appCategorizationID: "app-1",
            pointsSpent: 30,
            timeGrantedMinutes: 3,
            conversionRate: 10.0,
            redeemedAt: now.addingTimeInterval(-7200), // 2 hours ago
            expiresAt: now.addingTimeInterval(-3600), // Expired 1 hour ago
            timeUsedMinutes: 0,
            status: .active
        )
        let usedRedemption = PointToTimeRedemption(
            id: "used-1",
            childProfileID: "child-1",
            appCategorizationID: "app-1",
            pointsSpent: 40,
            timeGrantedMinutes: 4,
            conversionRate: 10.0,
            redeemedAt: now,
            expiresAt: now.addingTimeInterval(3600),
            timeUsedMinutes: 4,
            status: .used
        )

        mockPointToTimeRedemptionRepository.mockRedemptions = [activeRedemption, expiredRedemption, usedRedemption]

        // When
        let activeRedemptions = try await pointRedemptionService.getActiveRedemptions(for: "child-1")

        // Then
        XCTAssertEqual(activeRedemptions.count, 1)
        XCTAssertEqual(activeRedemptions.first?.id, "active-1")
    }

    // MARK: - Update Used Time Tests

    func testUpdateUsedTime_PartialUsage() async throws {
        // Given
        let redemption = PointToTimeRedemption(
            id: "redemption-1",
            childProfileID: "child-1",
            appCategorizationID: "app-1",
            pointsSpent: 50,
            timeGrantedMinutes: 5,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            timeUsedMinutes: 0,
            status: .active
        )

        mockPointToTimeRedemptionRepository.mockRedemption = redemption

        // When
        try await pointRedemptionService.updateUsedTime(redemptionID: "redemption-1", usedMinutes: 3)

        // Then
        XCTAssertEqual(mockPointToTimeRedemptionRepository.updatedRedemptions.count, 1)
        let updatedRedemption = mockPointToTimeRedemptionRepository.updatedRedemptions.first!
        XCTAssertEqual(updatedRedemption.timeUsedMinutes, 3)
        XCTAssertEqual(updatedRedemption.status, .active) // Still active since not fully used
    }

    func testUpdateUsedTime_FullUsage() async throws {
        // Given
        let redemption = PointToTimeRedemption(
            id: "redemption-1",
            childProfileID: "child-1",
            appCategorizationID: "app-1",
            pointsSpent: 50,
            timeGrantedMinutes: 5,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            timeUsedMinutes: 3,
            status: .active
        )

        mockPointToTimeRedemptionRepository.mockRedemption = redemption

        // When
        try await pointRedemptionService.updateUsedTime(redemptionID: "redemption-1", usedMinutes: 5)

        // Then
        let updatedRedemption = mockPointToTimeRedemptionRepository.updatedRedemptions.first!
        XCTAssertEqual(updatedRedemption.timeUsedMinutes, 5)
        XCTAssertEqual(updatedRedemption.status, .used) // Should be marked as used
    }
}

// MARK: - Mock Repositories

class MockChildProfileRepository: ChildProfileRepository {
    var mockChild: ChildProfile?
    var updatedChildren: [ChildProfile] = []
    var shouldThrowError = false

    func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError { throw MockError.repositoryError }
        return child
    }

    func fetchChild(id: String) async throws -> ChildProfile? {
        if shouldThrowError { throw MockError.repositoryError }
        return mockChild
    }

    func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        if shouldThrowError { throw MockError.repositoryError }
        return mockChild != nil ? [mockChild!] : []
    }

    func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError { throw MockError.repositoryError }
        updatedChildren.append(child)
        return child
    }

    func deleteChild(id: String) async throws {
        if shouldThrowError { throw MockError.repositoryError }
    }
}

class MockPointToTimeRedemptionRepository: PointToTimeRedemptionRepository {
    var mockRedemption: PointToTimeRedemption?
    var mockRedemptions: [PointToTimeRedemption] = []
    var createdRedemptions: [PointToTimeRedemption] = []
    var updatedRedemptions: [PointToTimeRedemption] = []
    var shouldThrowError = false

    func createPointToTimeRedemption(_ redemption: PointToTimeRedemption) async throws -> PointToTimeRedemption {
        if shouldThrowError { throw MockError.repositoryError }
        createdRedemptions.append(redemption)
        return redemption
    }

    func fetchPointToTimeRedemption(id: String) async throws -> PointToTimeRedemption? {
        if shouldThrowError { throw MockError.repositoryError }
        return mockRedemption
    }

    func fetchPointToTimeRedemptions(for childID: String) async throws -> [PointToTimeRedemption] {
        if shouldThrowError { throw MockError.repositoryError }
        return mockRedemptions.filter { $0.childProfileID == childID }
    }

    func fetchActivePointToTimeRedemptions(for childID: String) async throws -> [PointToTimeRedemption] {
        if shouldThrowError { throw MockError.repositoryError }
        return mockRedemptions.filter { $0.childProfileID == childID && $0.status == .active }
    }

    func updatePointToTimeRedemption(_ redemption: PointToTimeRedemption) async throws -> PointToTimeRedemption {
        if shouldThrowError { throw MockError.repositoryError }
        updatedRedemptions.append(redemption)
        return redemption
    }

    func deletePointToTimeRedemption(id: String) async throws {
        if shouldThrowError { throw MockError.repositoryError }
    }
}

class MockPointTransactionRepository: PointTransactionRepository {
    var createdTransactions: [PointTransaction] = []
    var shouldThrowError = false

    func createTransaction(_ transaction: PointTransaction) async throws -> PointTransaction {
        if shouldThrowError { throw MockError.repositoryError }
        createdTransactions.append(transaction)
        return transaction
    }

    func fetchTransaction(id: String) async throws -> PointTransaction? {
        if shouldThrowError { throw MockError.repositoryError }
        return nil
    }

    func fetchTransactions(for childID: String, limit: Int?) async throws -> [PointTransaction] {
        if shouldThrowError { throw MockError.repositoryError }
        return []
    }

    func fetchTransactions(for childID: String, dateRange: DateRange?) async throws -> [PointTransaction] {
        if shouldThrowError { throw MockError.repositoryError }
        return []
    }

    func deleteTransaction(id: String) async throws {
        if shouldThrowError { throw MockError.repositoryError }
    }
}

class MockAppCategorizationRepository: AppCategorizationRepository {
    var mockCategorization: AppCategorization?
    var shouldThrowError = false

    func createAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
        if shouldThrowError { throw MockError.repositoryError }
        return categorization
    }

    func fetchAppCategorization(id: String) async throws -> AppCategorization? {
        if shouldThrowError { throw MockError.repositoryError }
        return mockCategorization
    }

    func fetchAppCategorizations(for childID: String) async throws -> [AppCategorization] {
        if shouldThrowError { throw MockError.repositoryError }
        return []
    }

    func updateAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
        if shouldThrowError { throw MockError.repositoryError }
        return categorization
    }

    func deleteAppCategorization(id: String) async throws {
        if shouldThrowError { throw MockError.repositoryError }
    }
}

enum MockError: Error {
    case repositoryError
}

extension MockError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .repositoryError:
            return "Mock repository error"
        }
    }
}