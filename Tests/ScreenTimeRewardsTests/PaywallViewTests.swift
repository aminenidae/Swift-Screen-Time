import XCTest
import SwiftUI
import SharedModels
@testable import ScreenTimeRewards

@available(iOS 15.0, *)
final class PaywallViewTests: XCTestCase {

    func testPaywallViewCreation() {
        // Given: Mock family repository and family ID
        let mockRepo = MockFamilyRepository()
        let familyID = "test-family"

        // When: Creating PaywallView
        let paywall = PaywallView(familyID: familyID, familyRepository: mockRepo)

        // Then: View should be created without error
        XCTAssertNotNil(paywall)
    }

    func testFeatureRowCreation() {
        // Given: Feature row properties
        let icon = "checkmark.circle.fill"
        let text = "Test feature"
        let color = Color.green

        // When: Creating FeatureRow
        let featureRow = FeatureRow(icon: icon, text: text, color: color)

        // Then: View should be created without error
        XCTAssertNotNil(featureRow)
    }

    func testSubscriptionPlanCardCreation() {
        // Given: Mock subscription product
        let product = SubscriptionProduct(
            id: "test.product",
            displayName: "Test Product",
            description: "Test Description",
            price: 9.99,
            priceFormatted: "$9.99",
            subscriptionPeriod: SubscriptionPeriod(unit: .month, value: 1),
            familyShareable: true
        )

        // When: Creating SubscriptionPlanCard
        let planCard = SubscriptionPlanCard(product: product) {
            // Mock purchase action
        }

        // Then: View should be created without error
        XCTAssertNotNil(planCard)
    }
}

// MARK: - Mock Repository

fileprivate class MockFamilyRepository: FamilyRepository {
    func createFamily(_ family: Family) async throws -> Family {
        return family
    }

    func fetchFamily(id: String) async throws -> Family? {
        return Family(
            id: id,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: [],
            parentalConsentGiven: false,
            parentalConsentDate: nil,
            parentalConsentMethod: nil,
            subscriptionMetadata: nil
        )
    }

    func fetchFamilies(for userID: String) async throws -> [Family] {
        return []
    }

    func updateFamily(_ family: Family) async throws -> Family {
        return family
    }

    func deleteFamily(id: String) async throws {
        // No-op for mock
    }
}