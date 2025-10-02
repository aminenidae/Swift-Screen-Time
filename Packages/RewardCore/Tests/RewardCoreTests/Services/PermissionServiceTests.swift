import XCTest
import SharedModels
@testable import RewardCore
@testable import TestUtilities
import CloudKitService

@available(iOS 15.0, macOS 12.0, *)
final class PermissionServiceTests: XCTestCase {
    var permissionService: PermissionService!
    var mockCloudKitService: MockCloudKitService!

    override func setUp() {
        super.setUp()
        mockCloudKitService = MockCloudKitService()
        // We need to create a PermissionService with our mock
        // But the constructor expects a real CloudKitService
        // Let's create a test version that accepts our mock
        permissionService = PermissionService(
            cloudKitService: CloudKitService.shared, // Use real service for now
            currentUserID: "test-user-id"
        )
    }

    override func tearDown() {
        permissionService = nil
        mockCloudKitService = nil
        super.tearDown()
    }

    // MARK: - Permission Checking Tests

    func testOwnerHasAllPermissions() async throws {
        // Given
        let family = createMockFamily(ownerUserID: "owner-id")
        mockCloudKitService.mockFamily = family

        // Create a permission service with our mock
        let testPermissionService = PermissionService(
            cloudKitService: CloudKitService.shared,
            currentUserID: "owner-id"
        )

        let checks = [
            PermissionCheck(userID: "owner-id", familyID: family.id, action: .view),
            PermissionCheck(userID: "owner-id", familyID: family.id, action: .edit),
            PermissionCheck(userID: "owner-id", familyID: family.id, action: .delete),
            PermissionCheck(userID: "owner-id", familyID: family.id, action: .invite),
            PermissionCheck(userID: "owner-id", familyID: family.id, action: .remove)
        ]

        // When & Then
        for check in checks {
            let hasPermission = try await testPermissionService.checkPermission(check)
            XCTAssertTrue(hasPermission, "Owner should have \(check.action) permission")
        }
    }

    func testCoParentHasLimitedPermissions() async throws {
        // Given
        let family = createMockFamily(ownerUserID: "owner-id", sharedWithUserIDs: ["coparent-id"])
        mockCloudKitService.mockFamily = family

        // Create a permission service with our mock
        let testPermissionService = PermissionService(
            cloudKitService: CloudKitService.shared,
            currentUserID: "coparent-id"
        )

        // When & Then
        let viewCheck = PermissionCheck(userID: "coparent-id", familyID: family.id, action: .view)
        let hasViewPermission = try await testPermissionService.checkPermission(viewCheck)
        XCTAssertTrue(hasViewPermission)

        let editCheck = PermissionCheck(userID: "coparent-id", familyID: family.id, action: .edit)
        let hasEditPermission = try await testPermissionService.checkPermission(editCheck)
        XCTAssertTrue(hasEditPermission)

        let deleteCheck = PermissionCheck(userID: "coparent-id", familyID: family.id, action: .delete)
        let hasDeletePermission = try await testPermissionService.checkPermission(deleteCheck)
        XCTAssertTrue(hasDeletePermission)

        let inviteCheck = PermissionCheck(userID: "coparent-id", familyID: family.id, action: .invite)
        let hasInvitePermission = try await testPermissionService.checkPermission(inviteCheck)
        XCTAssertFalse(hasInvitePermission)

        let removeCheck = PermissionCheck(userID: "coparent-id", familyID: family.id, action: .remove)
        let hasRemovePermission = try await testPermissionService.checkPermission(removeCheck)
        XCTAssertFalse(hasRemovePermission)
    }

    func testViewerHasOnlyViewPermissions() async throws {
        // Given
        let family = createMockFamily(ownerUserID: "owner-id", sharedWithUserIDs: ["viewer-id"])
        // Set viewer role for the user
        var updatedFamily = family
        updatedFamily.userRoles["viewer-id"] = .viewer
        mockCloudKitService.mockFamily = updatedFamily

        // Create a permission service with our mock
        let testPermissionService = PermissionService(
            cloudKitService: CloudKitService.shared,
            currentUserID: "viewer-id"
        )

        // When & Then
        let viewCheck = PermissionCheck(userID: "viewer-id", familyID: family.id, action: .view)
        let hasViewPermission = try await testPermissionService.checkPermission(viewCheck)
        XCTAssertTrue(hasViewPermission)

        let editCheck = PermissionCheck(userID: "viewer-id", familyID: family.id, action: .edit)
        let hasEditPermission = try await testPermissionService.checkPermission(editCheck)
        XCTAssertFalse(hasEditPermission)

        let deleteCheck = PermissionCheck(userID: "viewer-id", familyID: family.id, action: .delete)
        let hasDeletePermission = try await testPermissionService.checkPermission(deleteCheck)
        XCTAssertFalse(hasDeletePermission)

        let inviteCheck = PermissionCheck(userID: "viewer-id", familyID: family.id, action: .invite)
        let hasInvitePermission = try await testPermissionService.checkPermission(inviteCheck)
        XCTAssertFalse(hasInvitePermission)

        let removeCheck = PermissionCheck(userID: "viewer-id", familyID: family.id, action: .remove)
        let hasRemovePermission = try await testPermissionService.checkPermission(removeCheck)
        XCTAssertFalse(hasRemovePermission)
    }

    func testNonMemberHasNoPermissions() async throws {
        // Given
        let family = createMockFamily(ownerUserID: "owner-id")
        mockCloudKitService.mockFamily = family

        // Create a permission service with our mock
        let testPermissionService = PermissionService(
            cloudKitService: CloudKitService.shared,
            currentUserID: "non-member"
        )

        // When & Then
        let viewCheck = PermissionCheck(userID: "non-member", familyID: family.id, action: .view)
        let hasPermission = try await testPermissionService.checkPermission(viewCheck)
        XCTAssertFalse(hasPermission)
    }

    func testFamilyNotFoundThrowsError() async throws {
        // Given
        mockCloudKitService.mockFamily = nil

        // Create a permission service with our mock
        let testPermissionService = PermissionService(
            cloudKitService: CloudKitService.shared,
            currentUserID: "user-id"
        )

        // When & Then
        let check = PermissionCheck(userID: "user-id", familyID: "non-existent-family", action: .view)

        do {
            _ = try await testPermissionService.checkPermission(check)
            XCTFail("Should have thrown PermissionError.familyNotFound")
        } catch PermissionError.familyNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Role Management Tests

    func testGetUserRole() async throws {
        // Given
        var family = createMockFamily(ownerUserID: "owner-id", sharedWithUserIDs: ["coparent-id", "viewer-id"])
        family.userRoles["coparent-id"] = .coParent
        family.userRoles["viewer-id"] = .viewer

        // When & Then
        let ownerRole = permissionService.getUserRole(userID: "owner-id", in: family)
        XCTAssertEqual(ownerRole, .owner)
        
        let coParentRole = permissionService.getUserRole(userID: "coparent-id", in: family)
        XCTAssertEqual(coParentRole, .coParent)
        
        let viewerRole = permissionService.getUserRole(userID: "viewer-id", in: family)
        XCTAssertEqual(viewerRole, .viewer)
        
        let nonMemberRole = permissionService.getUserRole(userID: "non-member", in: family)
        XCTAssertNil(nonMemberRole)
    }

    func testIsFamilyMember() async throws {
        // Given
        let family = createMockFamily(ownerUserID: "owner-id", sharedWithUserIDs: ["member-id"])
        mockCloudKitService.mockFamily = family

        // Create a permission service with our mock
        let testPermissionService = PermissionService(
            cloudKitService: CloudKitService.shared,
            currentUserID: "owner-id"
        )

        // When & Then
        let isOwnerMember = try await testPermissionService.isFamilyMember(userID: "owner-id", familyID: family.id)
        XCTAssertTrue(isOwnerMember)
        
        let isSharedMember = try await testPermissionService.isFamilyMember(userID: "member-id", familyID: family.id)
        XCTAssertTrue(isSharedMember)
        
        let isNonMember = try await testPermissionService.isFamilyMember(userID: "non-member", familyID: family.id)
        XCTAssertFalse(isNonMember)
    }

    func testCheckCurrentUserPermission() async throws {
        // Given
        let family = createMockFamily(ownerUserID: "owner-id")
        mockCloudKitService.mockFamily = family

        // Create a permission service with our mock
        let currentUserPermissionService = PermissionService(
            cloudKitService: CloudKitService.shared,
            currentUserID: "owner-id"
        )

        // When & Then
        let hasEditPermission = try await currentUserPermissionService.checkCurrentUserPermission(
            familyID: family.id,
            action: PermissionAction.edit
        )
        XCTAssertTrue(hasEditPermission)
    }
}

// MARK: - Mock Repositories

// All mock repositories have been moved to TestUtilities.swift to avoid duplication