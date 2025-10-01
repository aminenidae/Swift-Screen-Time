import XCTest
import Combine
@testable import ScreenTimeRewards
import SharedModels

@MainActor
final class RewardRedemptionViewModelTests: XCTestCase {
    var viewModel: RewardRedemptionViewModel!
    var mockChildProfileRepository: MockChildProfileRepository!
    var mockAppCategorizationRepository: MockAppCategorizationRepository!
    var mockPointRedemptionService: MockPointRedemptionService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockChildProfileRepository = MockChildProfileRepository()
        mockAppCategorizationRepository = MockAppCategorizationRepository()
        mockPointRedemptionService = MockPointRedemptionService()

        viewModel = RewardRedemptionViewModel(
            childProfileRepository: mockChildProfileRepository,
            appCategorizationRepository: mockAppCategorizationRepository,
            pointRedemptionService: mockPointRedemptionService
        )
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        viewModel = nil
        mockChildProfileRepository = nil
        mockAppCategorizationRepository = nil
        mockPointRedemptionService = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.currentPoints, 0)
        XCTAssertTrue(viewModel.rewardApps.isEmpty)
        XCTAssertNil(viewModel.selectedRewardApp)
        XCTAssertEqual(viewModel.conversionAmount, 0)
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isProcessingRedemption)
        XCTAssertFalse(viewModel.showingRedemptionAlert)
        XCTAssertFalse(viewModel.canRedeem)
    }

    // MARK: - Load Reward Apps Tests

    func testLoadRewardApps_Success() async {
        // Given
        let mockChild = ChildProfile(
            id: "mock-child-id",
            familyID: "family-1",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 450
        )
        let mockApps = [
            AppCategorization(id: "1", appBundleID: "com.game1.app", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 120),
            AppCategorization(id: "2", appBundleID: "com.game2.app", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 100),
            AppCategorization(id: "3", appBundleID: "com.learning.app", category: .learning, childProfileID: "mock-child-id", pointsPerHour: 60)
        ]

        mockChildProfileRepository.mockChild = mockChild
        mockAppCategorizationRepository.mockCategorizations = mockApps

        // When
        await viewModel.loadRewardApps()

        // Then
        XCTAssertEqual(viewModel.currentPoints, 450)
        XCTAssertEqual(viewModel.rewardApps.count, 3)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadRewardApps_Error() async {
        // Given
        mockChildProfileRepository.shouldThrowError = true

        // When
        await viewModel.loadRewardApps()

        // Then
        XCTAssertEqual(viewModel.currentPoints, 0)
        XCTAssertTrue(viewModel.rewardApps.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.showingRedemptionAlert)
        XCTAssertNotNil(viewModel.redemptionMessage)
    }

    // MARK: - Filtering Tests

    func testFilteredRewardApps_OnlyRewardCategory() {
        // Given
        viewModel.rewardApps = [
            AppCategorization(id: "1", appBundleID: "com.game1.app", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 120),
            AppCategorization(id: "2", appBundleID: "com.learning.app", category: .learning, childProfileID: "mock-child-id", pointsPerHour: 60),
            AppCategorization(id: "3", appBundleID: "com.game2.app", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 100)
        ]

        // When & Then (default filter shows only reward apps)
        let filtered = viewModel.filteredRewardApps
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.category == .reward })
        // Should be sorted by pointsPerHour descending
        XCTAssertEqual(filtered[0].pointsPerHour, 120)
        XCTAssertEqual(filtered[1].pointsPerHour, 100)
    }

    func testFilteredRewardApps_WithSearchText() {
        // Given
        viewModel.rewardApps = [
            AppCategorization(id: "1", appBundleID: "com.supercell.clashofclans", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 120),
            AppCategorization(id: "2", appBundleID: "com.king.candycrushsaga", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 100)
        ]
        viewModel.searchText = "clash"

        // When
        let filtered = viewModel.filteredRewardApps

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertTrue(filtered[0].appBundleID.contains("clashofclans"))
    }

    // MARK: - App Selection Tests

    func testSelectRewardApp() {
        // Given
        let app = AppCategorization(id: "1", appBundleID: "com.game.app", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 120)
        viewModel.currentPoints = 100

        // When
        viewModel.selectRewardApp(app)

        // Then
        XCTAssertEqual(viewModel.selectedRewardApp?.id, app.id)
        XCTAssertEqual(viewModel.conversionAmount, 10) // Default minimum (10 points = 1 minute)
    }

    func testSelectRewardApp_WithInsufficientPoints() {
        // Given
        let app = AppCategorization(id: "1", appBundleID: "com.game.app", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 120)
        viewModel.currentPoints = 5 // Less than minimum 10

        // When
        viewModel.selectRewardApp(app)

        // Then
        XCTAssertEqual(viewModel.selectedRewardApp?.id, app.id)
        XCTAssertEqual(viewModel.conversionAmount, 5) // Limited by available points
    }

    // MARK: - Conversion Amount Adjustment Tests

    func testAdjustConversionAmount_Increase() {
        // Given
        viewModel.currentPoints = 100
        viewModel.conversionAmount = 10

        // When
        viewModel.adjustConversionAmount(10)

        // Then
        XCTAssertEqual(viewModel.conversionAmount, 20)
    }

    func testAdjustConversionAmount_Decrease() {
        // Given
        viewModel.currentPoints = 100
        viewModel.conversionAmount = 30

        // When
        viewModel.adjustConversionAmount(-10)

        // Then
        XCTAssertEqual(viewModel.conversionAmount, 20)
    }

    func testAdjustConversionAmount_MinimumLimit() {
        // Given
        viewModel.currentPoints = 100
        viewModel.conversionAmount = 10

        // When
        viewModel.adjustConversionAmount(-10)

        // Then
        XCTAssertEqual(viewModel.conversionAmount, 10) // Should not go below minimum
    }

    func testAdjustConversionAmount_MaximumLimit() {
        // Given
        viewModel.currentPoints = 50
        viewModel.conversionAmount = 40

        // When
        viewModel.adjustConversionAmount(20)

        // Then
        XCTAssertEqual(viewModel.conversionAmount, 50) // Should not exceed available points
    }

    // MARK: - Can Redeem Tests

    func testCanRedeem_ValidConditions() {
        // Given
        let app = AppCategorization(id: "1", appBundleID: "com.game.app", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 120)
        viewModel.selectedRewardApp = app
        viewModel.currentPoints = 100
        viewModel.conversionAmount = 20

        // When & Then
        XCTAssertTrue(viewModel.canRedeem)
    }

    func testCanRedeem_NoSelectedApp() {
        // Given
        viewModel.selectedRewardApp = nil
        viewModel.currentPoints = 100
        viewModel.conversionAmount = 20

        // When & Then
        XCTAssertFalse(viewModel.canRedeem)
    }

    func testCanRedeem_InsufficientPoints() {
        // Given
        let app = AppCategorization(id: "1", appBundleID: "com.game.app", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 120)
        viewModel.selectedRewardApp = app
        viewModel.currentPoints = 50
        viewModel.conversionAmount = 60

        // When & Then
        XCTAssertFalse(viewModel.canRedeem)
    }

    func testCanRedeem_BelowMinimumAmount() {
        // Given
        let app = AppCategorization(id: "1", appBundleID: "com.game.app", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 120)
        viewModel.selectedRewardApp = app
        viewModel.currentPoints = 100
        viewModel.conversionAmount = 5 // Below minimum 10

        // When & Then
        XCTAssertFalse(viewModel.canRedeem)
    }

    // MARK: - Redeem Points Tests

    func testRedeemPoints_Success() async {
        // Given
        let app = AppCategorization(id: "1", appBundleID: "com.game.app", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 120)
        viewModel.selectedRewardApp = app
        viewModel.currentPoints = 100
        viewModel.conversionAmount = 30
        mockPointRedemptionService.mockResult = .success

        // When
        await viewModel.redeemPoints()

        // Then
        XCTAssertTrue(viewModel.redemptionSuccess)
        XCTAssertEqual(viewModel.currentPoints, 70) // 100 - 30
        XCTAssertEqual(viewModel.conversionAmount, 0)
        XCTAssertNil(viewModel.selectedRewardApp)
        XCTAssertTrue(viewModel.showingRedemptionAlert)
        XCTAssertFalse(viewModel.isProcessingRedemption)
    }

    func testRedeemPoints_InsufficientPoints() async {
        // Given
        let app = AppCategorization(id: "1", appBundleID: "com.game.app", category: .reward, childProfileID: "mock-child-id", pointsPerHour: 120)
        viewModel.selectedRewardApp = app
        viewModel.currentPoints = 100
        viewModel.conversionAmount = 30
        mockPointRedemptionService.mockResult = .insufficientPoints(required: 30, available: 20)

        // When
        await viewModel.redeemPoints()

        // Then
        XCTAssertFalse(viewModel.redemptionSuccess)
        XCTAssertEqual(viewModel.currentPoints, 100) // Unchanged
        XCTAssertTrue(viewModel.showingRedemptionAlert)
        XCTAssertTrue(viewModel.redemptionMessage.contains("Insufficient points"))
    }
}

// MARK: - Mock Services

class MockAppCategorizationRepository: AppCategorizationRepository {
    var mockCategorizations: [AppCategorization] = []
    var shouldThrowError = false

    func createAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
        if shouldThrowError { throw MockError.repositoryError }
        return categorization
    }

    func fetchAppCategorization(id: String) async throws -> AppCategorization? {
        if shouldThrowError { throw MockError.repositoryError }
        return mockCategorizations.first { $0.id == id }
    }

    func fetchAppCategorizations(for childID: String) async throws -> [AppCategorization] {
        if shouldThrowError { throw MockError.repositoryError }
        return mockCategorizations.filter { $0.childProfileID == childID }
    }

    func updateAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
        if shouldThrowError { throw MockError.repositoryError }
        return categorization
    }

    func deleteAppCategorization(id: String) async throws {
        if shouldThrowError { throw MockError.repositoryError }
    }
}

class MockPointRedemptionService: PointRedemptionService {
    var mockResult: PointRedemptionService.RedemptionResult = .success

    override func redeemPointsForScreenTime(
        childID: String,
        appCategorizationID: String,
        pointsToSpend: Int,
        timeMinutes: Int
    ) async throws -> PointRedemptionService.RedemptionResult {
        return mockResult
    }
}