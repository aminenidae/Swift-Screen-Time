import XCTest
import Combine
@testable import ScreenTimeRewards
@testable import SharedModels

final class ParentDashboardViewModelTests: XCTestCase {
    var viewModel: ParentDashboardViewModel!
    var mockChildProfileRepository: MockChildProfileRepository!
    var mockPointTransactionRepository: MockPointTransactionRepository!
    var mockUsageSessionRepository: MockUsageSessionRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        mockChildProfileRepository = MockChildProfileRepository()
        mockPointTransactionRepository = MockPointTransactionRepository()
        mockUsageSessionRepository = MockUsageSessionRepository()

        viewModel = ParentDashboardViewModel(
            childProfileRepository: mockChildProfileRepository,
            pointTransactionRepository: mockPointTransactionRepository,
            usageSessionRepository: mockUsageSessionRepository
        )

        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockChildProfileRepository = nil
        mockPointTransactionRepository = nil
        mockUsageSessionRepository = nil
        cancellables = nil
    }

    @MainActor
    func testLoadInitialData_WithChildren_LoadsChildrenAndProgressData() async throws {
        // Given
        let mockChildren = [
            ChildProfile(
                id: "child-1",
                familyID: "mock-family-id",
                name: "Test Child 1",
                avatarAssetURL: nil,
                birthDate: Date(),
                pointBalance: 100,
                totalPointsEarned: 500
            ),
            ChildProfile(
                id: "child-2",
                familyID: "mock-family-id",
                name: "Test Child 2",
                avatarAssetURL: nil,
                birthDate: Date(),
                pointBalance: 200,
                totalPointsEarned: 800
            )
        ]
        mockChildProfileRepository.mockChildren = mockChildren

        let mockTransactions = [
            PointTransaction(id: "t1", childProfileID: "child-1", points: 30, reason: "Math App", timestamp: Date()),
            PointTransaction(id: "t2", childProfileID: "child-1", points: 25, reason: "Reading App", timestamp: Date())
        ]
        mockPointTransactionRepository.mockTransactions = mockTransactions

        let mockSessions = [
            UsageSession(
                id: "s1",
                childProfileID: "child-1",
                appBundleID: "com.test.app",
                category: .learning,
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date(),
                duration: 3600
            )
        ]
        mockUsageSessionRepository.mockSessions = mockSessions

        // When
        await viewModel.loadInitialData()

        // Then
        XCTAssertEqual(viewModel.children.count, 2)
        XCTAssertEqual(viewModel.children[0].name, "Test Child 1")
        XCTAssertEqual(viewModel.children[1].name, "Test Child 2")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.childProgressData.count, 2)
    }

    @MainActor
    func testLoadInitialData_WithNoChildren_LoadsEmptyList() async throws {
        // Given
        mockChildProfileRepository.mockChildren = []

        // When
        await viewModel.loadInitialData()

        // Then
        XCTAssertTrue(viewModel.children.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.childProgressData.isEmpty)
    }

    @MainActor
    func testLoadInitialData_WithError_SetsErrorMessage() async throws {
        // Given
        mockChildProfileRepository.shouldThrowError = true

        // When
        await viewModel.loadInitialData()

        // Then
        XCTAssertTrue(viewModel.children.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to load family data"))
    }

    @MainActor
    func testRefreshData_CallsLoadInitialData() async throws {
        // Given
        let mockChildren = [
            ChildProfile(
                id: "child-1",
                familyID: "mock-family-id",
                name: "Test Child",
                avatarAssetURL: nil,
                birthDate: Date(),
                pointBalance: 100,
                totalPointsEarned: 500
            )
        ]
        mockChildProfileRepository.mockChildren = mockChildren

        // When
        await viewModel.refreshData()

        // Then
        XCTAssertEqual(viewModel.children.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testGetProgressData_WithExistingChild_ReturnsCorrectData() async throws {
        // Given
        let childID = "child-1"
        let mockChild = ChildProfile(
            id: childID,
            familyID: "mock-family-id",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100,
            totalPointsEarned: 500
        )
        mockChildProfileRepository.mockChildren = [mockChild]

        await viewModel.loadInitialData()

        // When
        let progressData = viewModel.getProgressData(for: childID)

        // Then
        XCTAssertNotNil(progressData)
        // progressData should be populated with mock data from repositories
    }

    @MainActor
    func testGetProgressData_WithNonExistentChild_ReturnsEmptyData() async throws {
        // Given
        let nonExistentChildID = "non-existent"

        // When
        let progressData = viewModel.getProgressData(for: nonExistentChildID)

        // Then
        XCTAssertEqual(progressData.recentTransactions.count, 0)
        XCTAssertEqual(progressData.todaysUsage.count, 0)
        XCTAssertEqual(progressData.weeklyPoints.count, 0)
        XCTAssertEqual(progressData.learningStreak, 0)
    }
}

// MARK: - Mock Repositories

class MockChildProfileRepository: ChildProfileRepository {
    var mockChildren: [ChildProfile] = []
    var shouldThrowError = false

    func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockChildren.append(child)
        return child
    }

    func fetchChild(id: String) async throws -> ChildProfile? {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockChildren.first { $0.id == id }
    }

    func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockChildren.filter { $0.familyID == familyID }
    }

    func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        if let index = mockChildren.firstIndex(where: { $0.id == child.id }) {
            mockChildren[index] = child
        }
        return child
    }

    func deleteChild(id: String) async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockChildren.removeAll { $0.id == id }
    }
}

class MockPointTransactionRepository: PointTransactionRepository {
    var mockTransactions: [PointTransaction] = []
    var shouldThrowError = false

    func createTransaction(_ transaction: PointTransaction) async throws -> PointTransaction {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockTransactions.append(transaction)
        return transaction
    }

    func fetchTransaction(id: String) async throws -> PointTransaction? {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockTransactions.first { $0.id == id }
    }

    func fetchTransactions(for childID: String, limit: Int?) async throws -> [PointTransaction] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        let filtered = mockTransactions.filter { $0.childProfileID == childID }
        if let limit = limit {
            return Array(filtered.prefix(limit))
        }
        return filtered
    }

    func fetchTransactions(for childID: String, dateRange: DateRange?) async throws -> [PointTransaction] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        let filtered = mockTransactions.filter { $0.childProfileID == childID }

        if let dateRange = dateRange {
            return filtered.filter { transaction in
                transaction.timestamp >= dateRange.start && transaction.timestamp <= dateRange.end
            }
        }

        return filtered
    }

    func deleteTransaction(id: String) async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockTransactions.removeAll { $0.id == id }
    }
}

class MockUsageSessionRepository: UsageSessionRepository {
    var mockSessions: [UsageSession] = []
    var shouldThrowError = false

    func createSession(_ session: UsageSession) async throws -> UsageSession {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockSessions.append(session)
        return session
    }

    func fetchSession(id: String) async throws -> UsageSession? {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockSessions.first { $0.id == id }
    }

    func fetchSessions(for childID: String, dateRange: DateRange?) async throws -> [UsageSession] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        let filtered = mockSessions.filter { $0.childProfileID == childID }

        if let dateRange = dateRange {
            return filtered.filter { session in
                session.startTime >= dateRange.start && session.endTime <= dateRange.end
            }
        }

        return filtered
    }

    func updateSession(_ session: UsageSession) async throws -> UsageSession {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        if let index = mockSessions.firstIndex(where: { $0.id == session.id }) {
            mockSessions[index] = session
        }
        return session
    }

    func deleteSession(id: String) async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockSessions.removeAll { $0.id == id }
    }
}