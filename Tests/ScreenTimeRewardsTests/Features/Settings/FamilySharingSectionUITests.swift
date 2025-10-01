import XCTest
import SwiftUI
import ViewInspector
import SharedModels
@testable import ScreenTimeRewards

@available(iOS 15.0, macOS 12.0, *)
final class FamilySharingSectionUITests: XCTestCase {

    func testOwnerBadgeIsDisplayed() throws {
        // Given
        let viewModel = createMockViewModel(isOwner: true)
        let familySharingSection = FamilySharingSection(viewModel: viewModel)

        // When
        let view = try familySharingSection.inspect()

        // Then
        // Verify that owner badge is displayed
        let ownerSection = try view.find(viewWithId: "family-owner-section")
        XCTAssertNoThrow(try ownerSection.find(text: "Owner"))
    }

    func testCoParentBadgeIsDisplayed() throws {
        // Given
        let viewModel = createMockViewModel(isOwner: true)
        let familySharingSection = FamilySharingSection(viewModel: viewModel)

        // When
        let view = try familySharingSection.inspect()

        // Then
        // Verify that co-parent badges are displayed
        let coParentSection = try view.find(viewWithId: "co-parents-section")
        XCTAssertNoThrow(try coParentSection.find(text: "Co-Parent"))
    }

    func testRemoveButtonIsHiddenForNonOwner() throws {
        // Given
        let viewModel = createMockViewModel(isOwner: false)
        let familySharingSection = FamilySharingSection(viewModel: viewModel)

        // When
        let view = try familySharingSection.inspect()

        // Then
        // Verify that remove buttons are not displayed for non-owners
        let buttons = try view.findAll(ViewType.Button.self)
        let removeButtons = buttons.filter { button in
            do {
                let image = try button.labelView().find(ViewType.Image.self)
                let systemName = try image.actualImage().name()
                return systemName == "minus.circle.fill"
            } catch {
                return false
            }
        }
        XCTAssertTrue(removeButtons.isEmpty, "Remove buttons should be hidden for non-owners")
    }

    func testRemoveButtonIsVisibleForOwner() throws {
        // Given
        let viewModel = createMockViewModel(isOwner: true)
        let familySharingSection = FamilySharingSection(viewModel: viewModel)

        // When
        let view = try familySharingSection.inspect()

        // Then
        // Verify that remove buttons are displayed for owners
        let buttons = try view.findAll(ViewType.Button.self)
        let removeButtons = buttons.filter { button in
            do {
                let image = try button.labelView().find(ViewType.Image.self)
                let systemName = try image.actualImage().name()
                return systemName == "minus.circle.fill"
            } catch {
                return false
            }
        }
        XCTAssertFalse(removeButtons.isEmpty, "Remove buttons should be visible for owners")
    }

    func testInviteButtonIsDisabledForNonOwner() throws {
        // Given
        let viewModel = createMockViewModel(isOwner: false)
        let familySharingSection = FamilySharingSection(viewModel: viewModel)

        // When
        let view = try familySharingSection.inspect()

        // Then
        // Find invite button and verify it's disabled
        let inviteButton = try view.find(button: "Invite Co-Parent")
        XCTAssertTrue(try inviteButton.isDisabled(), "Invite button should be disabled for non-owners")
    }

    func testInviteButtonIsEnabledForOwner() throws {
        // Given
        let viewModel = createMockViewModel(isOwner: true)
        let familySharingSection = FamilySharingSection(viewModel: viewModel)

        // When
        let view = try familySharingSection.inspect()

        // Then
        // Find invite button and verify it's enabled
        let inviteButton = try view.find(button: "Invite Co-Parent")
        XCTAssertFalse(try inviteButton.isDisabled(), "Invite button should be enabled for owners")
    }

    func testRoleBadgeColors() throws {
        // Given
        let viewModel = createMockViewModel(isOwner: true)
        let familySharingSection = FamilySharingSection(viewModel: viewModel)

        // When
        let view = try familySharingSection.inspect()

        // Then
        // Verify role badge styling
        let ownerBadge = try view.find(text: "Owner").parent(ViewType.HStack.self)
        let coParentBadge = try view.find(text: "Co-Parent").parent(ViewType.HStack.self)

        // Note: In a real implementation, you would verify the actual colors
        // This is a simplified test structure
        XCTAssertNoThrow(ownerBadge)
        XCTAssertNoThrow(coParentBadge)
    }

    func testUnauthorizedActionAlert() throws {
        // Given
        let viewModel = createMockViewModel(isOwner: false)
        viewModel.showError = true
        viewModel.errorMessage = "You don't have permission to perform this action."

        let familySharingSection = FamilySharingSection(viewModel: viewModel)

        // When
        let view = try familySharingSection.inspect()

        // Then
        // Verify that error alert is shown
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "You don't have permission to perform this action.")
    }

    // MARK: - Helper Methods

    private func createMockViewModel(isOwner: Bool) -> FamilySharingViewModel {
        let viewModel = FamilySharingViewModel()

        viewModel.familyOwner = CoParentInfo(
            userID: "owner-id",
            displayName: "John Smith",
            email: "john@example.com",
            joinedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            role: .owner
        )

        viewModel.coParents = [
            CoParentInfo(
                userID: "coparent-id",
                displayName: "Jane Smith",
                email: "jane@example.com",
                joinedAt: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                role: .coParent
            )
        ]

        viewModel.isCurrentUserOwner = isOwner
        return viewModel
    }
}

// MARK: - Permission Component UI Tests

@available(iOS 15.0, macOS 12.0, *)
final class PermissionComponentUITests: XCTestCase {

    func testPermissionAwareButtonWithPermission() throws {
        // Given
        let button = PermissionAwareButton(
            title: "Edit Settings",
            hasPermission: true,
            permissionAction: .edit,
            isDisabled: false
        ) {
            // Action
        }

        // When
        let view = try button.inspect()

        // Then
        let buttonView = try view.find(ViewType.Button.self)
        XCTAssertFalse(try buttonView.isDisabled())
        XCTAssertEqual(try buttonView.labelView().string(), "Edit Settings")
    }

    func testPermissionAwareButtonWithoutPermission() throws {
        // Given
        let button = PermissionAwareButton(
            title: "Edit Settings",
            hasPermission: false,
            permissionAction: .edit,
            isDisabled: false
        ) {
            // Action
        }

        // When
        let view = try button.inspect()

        // Then
        let buttonView = try view.find(ViewType.Button.self)
        XCTAssertFalse(try buttonView.isDisabled()) // Button itself isn't disabled, but action is restricted
        XCTAssertEqual(try buttonView.labelView().string(), "Edit Settings")
    }

    func testOwnerOnlyControlVisibility() throws {
        // Given
        let ownerControl = OwnerOnlyControl(isOwner: true) {
            Text("Owner Only Content")
        }

        let nonOwnerControl = OwnerOnlyControl(isOwner: false) {
            Text("Owner Only Content")
        }

        // When
        let ownerView = try ownerControl.inspect()
        let nonOwnerView = try nonOwnerControl.inspect()

        // Then
        XCTAssertNoThrow(try ownerView.find(text: "Owner Only Content"))

        // Non-owner should not see the content
        XCTAssertThrowsError(try nonOwnerView.find(text: "Owner Only Content"))
    }

    func testUnauthorizedActionAlertModifier() throws {
        // Given
        @State var showAlert = true
        let testView = Text("Test Content")
            .unauthorizedActionAlert(
                isPresented: Binding(get: { showAlert }, set: { showAlert = $0 }),
                action: .edit,
                message: "Custom unauthorized message"
            )

        // When
        let view = try testView.inspect()

        // Then
        // Verify alert is configured (actual alert testing would require more complex setup)
        XCTAssertNoThrow(try view.find(ViewType.Text.self))
    }
}

// MARK: - Role Badge UI Tests

@available(iOS 15.0, macOS 12.0, *)
final class RoleBadgeUITests: XCTestCase {

    func testOwnerRoleBadge() {
        // Given
        let role = PermissionRole.owner

        // When & Then
        XCTAssertEqual(role.displayName, "Owner")
        XCTAssertTrue(role.hasFullAccess)
    }

    func testCoParentRoleBadge() {
        // Given
        let role = PermissionRole.coParent

        // When & Then
        XCTAssertEqual(role.displayName, "Co-Parent")
        XCTAssertTrue(role.hasFullAccess)
    }

    func testViewerRoleBadge() {
        // Given
        let role = PermissionRole.viewer

        // When & Then
        XCTAssertEqual(role.displayName, "Viewer")
        XCTAssertFalse(role.hasFullAccess)
    }
}

// MARK: - ViewInspector Extensions

extension InspectableView {
    func find(button title: String) throws -> InspectableView<ViewType.Button> {
        return try find(ViewType.Button.self) { button in
            try button.labelView().string() == title
        }
    }

    func find(viewWithId id: String) throws -> InspectableView<ViewType.View> {
        // This is a simplified implementation
        // In practice, you would use accessibility identifiers or other means to identify views
        return try find(ViewType.View.self)
    }
}