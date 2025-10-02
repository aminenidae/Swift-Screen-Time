import Foundation
import StoreKit

/// Product information for subscription products
@available(iOS 15.0, macOS 12.0, *)
public struct SubscriptionProduct: Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let description: String
    public let price: Decimal
    public let priceFormatted: String
    public let subscriptionPeriod: SubscriptionPeriod
    public let familyShareable: Bool
    public let introductoryOffer: Product.SubscriptionOffer?

    public init(
        id: String,
        displayName: String,
        description: String,
        price: Decimal,
        priceFormatted: String,
        subscriptionPeriod: SubscriptionPeriod,
        familyShareable: Bool,
        introductoryOffer: Product.SubscriptionOffer? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.price = price
        self.priceFormatted = priceFormatted
        self.subscriptionPeriod = subscriptionPeriod
        self.familyShareable = familyShareable
        self.introductoryOffer = introductoryOffer
    }
}

/// Subscription period information
public struct SubscriptionPeriod: Sendable {
    public let unit: Unit
    public let value: Int

    public enum Unit: Sendable {
        case day
        case week
        case month
        case year
    }

    public init(unit: Unit, value: Int) {
        self.unit = unit
        self.value = value
    }

    public var displayName: String {
        switch (unit, value) {
        case (.month, 1):
            return "Monthly"
        case (.year, 1):
            return "Yearly"
        case (.month, let count):
            return "\(count) Months"
        case (.year, let count):
            return "\(count) Years"
        case (.day, let count):
            return "\(count) Days"
        case (.week, let count):
            return "\(count) Weeks"
        }
    }
}

/// Product identifiers for all subscription products
public enum ProductIdentifiers {
    public static let oneChildMonthly = "screentime.1child.monthly"
    public static let twoChildMonthly = "screentime.2child.monthly"
    public static let oneChildYearly = "screentime.1child.yearly"
    public static let twoChildYearly = "screentime.2child.yearly"

    public static let allProducts = [
        oneChildMonthly,
        twoChildMonthly,
        oneChildYearly,
        twoChildYearly
    ]
}