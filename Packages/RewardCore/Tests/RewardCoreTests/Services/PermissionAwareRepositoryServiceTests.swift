import XCTest
import SharedModels
@testable import RewardCore
@testable import TestUtilities
import CloudKitService

@available(iOS 15.0, macOS 12.0, *)
final class PermissionAwareRepositoryServiceTests: XCTestCase {
    var repositoryService: PermissionAwareRepositoryService!
    var permissionService: PermissionService!
    var mockChildProfileRepository: MockChildProfileRepository!
    var mockAppCategorizationRepository: MockAppCategorizationRepository!
    var mockFamilyRepository: MockFamilyRepository!
    var mockUsageSessionRepository: MockUsageSessionRepository!
    var mockPointTransactionRepository: MockPointTransactionRepository!

    override func setUp() {
        super.setUp()

        mockChildProfileRepository = MockChildProfileRepository()
        mockAppCategorizationRepository = MockAppCategorizationRepository()
        mockFamilyRepository = MockFamilyRepository()
        mockUsageSessionRepository = MockUsageSessionRepository()
        mockPointTransactionRepository = MockPointTransactionRepository()

        permissionService = PermissionService(
            cloudKitService: CloudKitService.shared,
            currentUserID: "test-user"
        )

        repositoryService = PermissionAwareRepositoryService(
            permissionService: permissionService,
            childProfileRepository: mockChildProfileRepository,
            appCategorizationRepository: mockAppCategorizationRepository,
            familyRepository: mockFamilyRepository,
            usageSessionRepository: mockUsageSessionRepository,
            pointTransactionRepository: mockPointTransactionRepository
        )

        // Set up default family
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "owner-user",
            sharedWithUserIDs: ["coparent-user"],
            childProfileIDs: ["test-child"],
            userRoles: ["coparent-user": .coParent]
        )
        mockFamilyRepository.mockFamily = family

        let childProfile = ChildProfile(
            id: "test-child",
            familyID: "test-family",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100
        )
        mockChildProfileRepository.mockChild = childProfile
    }

    override func tearDown() {
        repositoryService = nil
        permissionService = nil
        mockChildProfileRepository = nil
        mockAppCategorizationRepository = nil
        mockFamilyRepository = nil
        mockUsageSessionRepository = nil
        mockPointTransactionRepository = nil
        super.tearDown()
    }

    // MARK: - Child Profile Permission Tests

    func testOwnerCanCreateChild() async throws {
        // Given
        let child = ChildProfile(
            id: "new-child",
            familyID: "test-family",
            name: "New Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 0
        )

        // When
        let createdChild = try await repositoryService.createChild(child, by: "owner-user")

        // Then
        XCTAssertEqual(createdChild.id, "new-child")
        XCTAssertTrue(mockChildProfileRepository.createChildCalled)
    }

    func testCoParentCanCreateChild() async throws {
        // Given
        let child = ChildProfile(
            id: "new-child",
            familyID: "test-family",
            name: "New Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 0
        )

        // When
        let createdChild = try await repositoryService.createChild(child, by: "coparent-user")

        // Then
        XCTAssertEqual(createdChild.id, "new-child")
        XCTAssertTrue(mockChildProfileRepository.createChildCalled)
    }

    func testUnauthorizedUserCannotCreateChild() async {
        // Given
        let child = ChildProfile(
            id: "new-child",
            familyID: "test-family",
            name: "New Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 0
        )

        // When & Then
        do {
            _ = try await repositoryService.createChild(child, by: "unauthorized-user")
            XCTFail("Should have thrown unauthorized error")
        } catch PermissionError.unauthorized {
            // Expected
            XCTAssertFalse(mockChildProfileRepository.createChildCalled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testOwnerCanDeleteChild() async throws {
        // When
        try await repositoryService.deleteChild(
            id: "test-child",
            from: "test-family",
            by: "owner-user"
        )

        // Then
        XCTAssertTrue(mockChildProfileRepository.deleteChildCalled)
    }

    func testUnauthorizedUserCannotDeleteChild() async {
        // When & Then
        do {
            try await repositoryService.deleteChild(
                id: "test-child",
                from: "test-family",
                by: "unauthorized-user"
            )
            XCTFail("Should have thrown unauthorized error")
        } catch PermissionError.unauthorized {
            // Expected
            XCTAssertFalse(mockChildProfileRepository.deleteChildCalled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - App Categorization Permission Tests

    func testOwnerCanCreateAppCategorization() async throws {
        // Given
        let categorization = AppCategorization(
            id: "test-cat",
            appBundleID: "com.test.app",
            category: .learning,
            childProfileID: "test-child",
            pointsPerHour: 10
        )

        // When
        let createdCategorization = try await repositoryService.createAppCategorization(
            categorization,
            by: "owner-user"
        )

        // Then
        XCTAssertEqual(createdCategorization.id, "test-cat")
        XCTAssertTrue(mockAppCategorizationRepository.createCalled)
    }

    func testCoParentCanCreateAppCategorization() async throws {
        // Given
        let categorization = AppCategorization(
            id: "test-cat",
            appBundleID: "com.test.app",
            category: .learning,
            childProfileID: "test-child",
            pointsPerHour: 10
        )

        // When
        let createdCategorization = try await repositoryService.createAppCategorization(
            categorization,
            by: "coparent-user"
        )

        // Then
        XCTAssertEqual(createdCategorization.id, "test-cat")
        XCTAssertTrue(mockAppCategorizationRepository.createCalled)
    }

    func testUnauthorizedUserCannotCreateAppCategorization() async {
        // Given
        let categorization = AppCategorization(
            id: "test-cat",
            appBundleID: "com.test.app",
            category: .learning,
            childProfileID: "test-child",
            pointsPerHour: 10
        )

        // When & Then
        do {
            _ = try await repositoryService.createAppCategorization(
                categorization,
                by: "unauthorized-user"
            )
            XCTFail("Should have thrown unauthorized error")
        } catch PermissionError.unauthorized {
            // Expected
            XCTAssertFalse(mockAppCategorizationRepository.createCalled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Family Permission Tests

    func testOwnerCanUpdateFamily() async throws {
        // Given
        guard let family = mockFamilyRepository.mockFamily else {
            XCTFail("Mock family should be available")
            return
        }

        // When
        let updatedFamily = try await repositoryService.updateFamily(family, by: "owner-user")

        // Then
        XCTAssertEqual(updatedFamily.id, "test-family")
        XCTAssertTrue(mockFamilyRepository.updateFamilyCalled)
    }

    func testCoParentCanUpdateFamily() async throws {
        // Given
        guard let family = mockFamilyRepository.mockFamily else {
            XCTFail("Mock family should be available")
            return
        }

        // When
        let updatedFamily = try await repositoryService.updateFamily(family, by: "coparent-user")

        // Then
        XCTAssertEqual(updatedFamily.id, "test-family")
        XCTAssertTrue(mockFamilyRepository.updateFamilyCalled)
    }

    func testUnauthorizedUserCannotUpdateFamily() async {
        // Given
        guard let family = mockFamilyRepository.mockFamily else {
            XCTFail("Mock family should be available")
            return
        }

        // When & Then
        do {
            _ = try await repositoryService.updateFamily(family, by: "unauthorized-user")
            XCTFail("Should have thrown unauthorized error")
        } catch PermissionError.unauthorized {
            // Expected
            XCTAssertFalse(mockFamilyRepository.updateFamilyCalled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Permission Management Tests

    func testOwnerCanAssignRoles() async throws {
        // When
        let updatedFamily = try await repositoryService.assignUserRole(
            .viewer,
            to: "new-user",
            in: "test-family",
            by: "owner-user"
        )

        // Then
        XCTAssertEqual(updatedFamily.userRoles["new-user"], .viewer)
    }

    func testCoParentCannotAssignRoles() async {
        // When & Then
        do {
            _ = try await repositoryService.assignUserRole(
                .viewer,
                to: "new-user",
                in: "test-family",
                by: "coparent-user"
            )
            XCTFail("Should have thrown unauthorized error")
        } catch PermissionError.unauthorized {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetFamilyMembersWithPermissionCheck() async throws {
        // When
        let members = try await repositoryService.getFamilyMembers(
            familyID: "test-family",
            by: "owner-user"
        )

        // Then
        XCTAssertEqual(members.count, 2) // owner + coparent
        XCTAssertTrue(members.contains { $0.userID == "owner-user" && $0.role == .owner })
        XCTAssertTrue(members.contains { $0.userID == "coparent-user" && $0.role == .coParent })
    }
}