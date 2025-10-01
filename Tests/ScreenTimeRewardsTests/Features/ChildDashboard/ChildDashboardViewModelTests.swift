import XCTest
import Combine
@testable import ScreenTimeRewards
import SharedModels

@MainActor
final class ChildDashboardViewModelTests: XCTestCase {
    var viewModel: ChildDashboardViewModel!
    var mockChildProfileRepository: MockChildProfileRepository!
    var mockPointTransactionRepository: MockPointTransactionRepository!
    var mockUsageSessionRepository: MockUsageSessionRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockChildProfileRepository = MockChildProfileRepository()
        mockPointTransactionRepository = MockPointTransactionRepository()
        mockUsageSessionRepository = MockUsageSessionRepository()
        viewModel = ChildDashboardViewModel(
            childProfileRepository: mockChildProfileRepository,
            pointTransactionRepository: mockPointTransactionRepository,
            usageSessionRepository: mockUsageSessionRepository
        )
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        viewModel = nil
        mockChildProfileRepository = nil
        mockPointTransactionRepository = nil
        mockUsageSessionRepository = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.currentPoints, 0)
        XCTAssertEqual(viewModel.totalPointsEarned, 0)
        XCTAssertTrue(viewModel.recentTransactions.isEmpty)
        XCTAssertTrue(viewModel.recentSessions.isEmpty)
        XCTAssertEqual(viewModel.pointsAnimationScale, 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.dailyGoal, 100)
        XCTAssertTrue(viewModel.availableRewards.isEmpty)
        XCTAssertEqual(viewModel.floatingPointsNotification, 0)
        XCTAssertFalse(viewModel.showFloatingNotification)
    }

    // MARK: - Load Initial Data Tests

    func testLoadInitialData_Success() async {
        // Given
        let mockChild = ChildProfile(
            id: "mock-child-id",
            familyID: "family-1",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 450,
            totalPointsEarned: 1250
        )
        let mockTransactions = [
            PointTransaction(id: "1", childProfileID: "mock-child-id", points: 30, reason: "Math App", timestamp: Date()),
            PointTransaction(id: "2", childProfileID: "mock-child-id", points: 45, reason: "Reading App", timestamp: Date())
        ]

        mockChildProfileRepository.mockChild = mockChild
        mockPointTransactionRepository.mockTransactions = mockTransactions

        // When
        await viewModel.loadInitialData()

        // Then
        XCTAssertEqual(viewModel.currentPoints, 450)
        XCTAssertEqual(viewModel.totalPointsEarned, 1250)
        XCTAssertEqual(viewModel.recentTransactions.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.availableRewards.isEmpty) // Mock rewards are loaded
    }

    func testLoadInitialData_ChildProfileNotFound() async {
        // Given
        mockChildProfileRepository.mockChild = nil
        mockPointTransactionRepository.mockTransactions = []

        // When
        await viewModel.loadInitialData()

        // Then
        XCTAssertEqual(viewModel.currentPoints, 0)
        XCTAssertEqual(viewModel.totalPointsEarned, 0)
        XCTAssertTrue(viewModel.recentTransactions.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.availableRewards.isEmpty) // Mock rewards are still loaded
    }

    func testLoadInitialData_RepositoryError() async {
        // Given
        mockChildProfileRepository.shouldThrowError = true

        // When
        await viewModel.loadInitialData()

        // Then
        XCTAssertEqual(viewModel.currentPoints, 0)
        XCTAssertEqual(viewModel.totalPointsEarned, 0)
        XCTAssertTrue(viewModel.recentTransactions.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to load dashboard data") ?? false)
        XCTAssertFalse(viewModel.availableRewards.isEmpty) // Mock rewards are still loaded
    }

    // MARK: - Animation Tests

    func testAnimatePointsEarned() {
        // Given
        let expectation = XCTestExpectation(description: "Animation completed")
        var scaleValues: [CGFloat] = []

        viewModel.$pointsAnimationScale
            .sink { scale in
                scaleValues.append(scale)
                if scaleValues.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.animatePointsEarned(points: 5)

        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(scaleValues.first, 1.0) // Initial value
        XCTAssertEqual(scaleValues[1], 1.2) // Animated value
    }

    func testFloatingPointsNotification() {
        // Given
        let pointsToShow = 10
        
        // When
        viewModel.animatePointsEarned(points: pointsToShow)

        // Then
        XCTAssertTrue(viewModel.showFloatingNotification)
        XCTAssertEqual(viewModel.floatingPointsNotification, pointsToShow)
    }

    // MARK: - Reward Redemption Tests

    func testRedeemReward_WithSufficientPoints() {
        // Given
        viewModel.currentPoints = 100
        let reward = Reward(
            id: "1",
            name: "Game Time",
            description: "30 minutes of game time",
            pointCost: 50,
            imageURL: nil,
            isActive: true,
            createdAt: Date()
        )
        let initialPoints = viewModel.currentPoints

        // When
        viewModel.redeemReward(reward)

        // Then
        XCTAssertEqual(viewModel.currentPoints, initialPoints - reward.pointCost)
    }

    func testRedeemReward_WithInsufficientPoints() {
        // Given
        viewModel.currentPoints = 30
        let reward = Reward(
            id: "1",
            name: "Game Time",
            description: "30 minutes of game time",
            pointCost: 50,
            imageURL: nil,
            isActive: true,
            createdAt: Date()
        )
        let initialPoints = viewModel.currentPoints

        // When
        viewModel.redeemReward(reward)

        // Then
        XCTAssertEqual(viewModel.currentPoints, initialPoints - reward.pointCost)
    }

    // MARK: - Refresh Data Tests

    func testRefreshData() async {
        // Given
        let mockChild = ChildProfile(
            id: "mock-child-id",
            familyID: "family-1",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 600,
            totalPointsEarned: 1500
        )
        mockChildProfileRepository.mockChild = mockChild

        // When
        await viewModel.refreshData()

        // Then
        XCTAssertEqual(viewModel.currentPoints, 600)
        XCTAssertEqual(viewModel.totalPointsEarned, 1500)
        XCTAssertFalse(viewModel.isLoading)
    }
}

// MARK: - Mock Repositories

class MockChildProfileRepository: ChildProfileRepository {
    var mockChild: ChildProfile?
    var shouldThrowError = false

    func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        return child
    }

    func fetchChild(id: String) async throws -> ChildProfile? {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        return mockChild
    }

    func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        return mockChild != nil ? [mockChild!] : []
    }

    func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        return child
    }

    func deleteChild(id: String) async throws {
        if shouldThrowError {
            throw MockError.repositoryError
        }
    }
}

class MockPointTransactionRepository: PointTransactionRepository {
    var mockTransactions: [PointTransaction] = []
    var shouldThrowError = false

    func createTransaction(_ transaction: PointTransaction) async throws -> PointTransaction {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        return transaction
    }

    func fetchTransaction(id: String) async throws -> PointTransaction? {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        return mockTransactions.first { $0.id == id }
    }

    func fetchTransactions(for childID: String, limit: Int?) async throws -> [PointTransaction] {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        let filtered = mockTransactions.filter { $0.childProfileID == childID }
        if let limit = limit {
            return Array(filtered.prefix(limit))
        }
        return filtered
    }

    func fetchTransactions(for childID: String, dateRange: DateRange?) async throws -> [PointTransaction] {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        return mockTransactions.filter { $0.childProfileID == childID }
    }

    func deleteTransaction(id: String) async throws {
        if shouldThrowError {
            throw MockError.repositoryError
        }
    }
}

class MockUsageSessionRepository: UsageSessionRepository {
    var mockSessions: [UsageSession] = []
    var shouldThrowError = false

    func createSession(_ session: UsageSession) async throws -> UsageSession {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        return session
    }

    func fetchSession(id: String) async throws -> UsageSession? {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        return mockSessions.first { $0.id == id }
    }

    func fetchSessions(for childID: String, dateRange: DateRange?) async throws -> [UsageSession] {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        return mockSessions.filter { $0.childProfileID == childID }
    }

    func updateSession(_ session: UsageSession) async throws -> UsageSession {
        if shouldThrowError {
            throw MockError.repositoryError
        }
        return session
    }

    func deleteSession(id: String) async throws {
        if shouldThrowError {
            throw MockError.repositoryError
        }
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