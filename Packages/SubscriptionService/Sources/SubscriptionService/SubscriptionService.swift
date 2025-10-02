import Foundation
import StoreKit
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class SubscriptionService: ObservableObject {
    @Published public private(set) var availableProducts: [SubscriptionProduct] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: AppError?

    private var productCache: [String: Product] = [:]
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes

    public init() {}

    /// Fetch all available subscription products
    public func fetchProducts() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let products = try await Product.products(for: ProductIdentifiers.allProducts)
            let subscriptionProducts = products.compactMap { product in
                convertToSubscriptionProduct(product)
            }

            // Cache products
            for product in products {
                productCache[product.id] = product
            }

            await MainActor.run {
                availableProducts = subscriptionProducts
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = mapStoreKitError(error)
                isLoading = false
            }
        }
    }

    /// Get cached product by ID
    public func getCachedProduct(for productId: String) -> SubscriptionProduct? {
        guard let product = productCache[productId] else { return nil }
        return convertToSubscriptionProduct(product)
    }

    /// Refresh products if cache is stale
    public func refreshProductsIfNeeded() async {
        if availableProducts.isEmpty {
            await fetchProducts()
        }
    }

    /// Purchase a subscription product
    public func purchase(_ productId: String) async throws -> Product.PurchaseResult {
        guard let product = productCache[productId] else {
            throw AppError.productNotFound(productId)
        }

        do {
            let result = try await product.purchase()
            return result
        } catch {
            throw mapStoreKitError(error)
        }
    }

    /// Restore purchases
    public func restorePurchases() async throws {
        do {
            try await AppStore.sync()
        } catch {
            throw mapStoreKitError(error)
        }
    }

    // MARK: - Private Methods

    private func convertToSubscriptionProduct(_ product: Product) -> SubscriptionProduct? {
        guard let subscription = product.subscription else { return nil }

        let subscriptionPeriod = SubscriptionPeriod(
            unit: mapSubscriptionUnit(subscription.subscriptionPeriod.unit),
            value: subscription.subscriptionPeriod.value
        )

        return SubscriptionProduct(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            price: product.price,
            priceFormatted: product.displayPrice,
            subscriptionPeriod: subscriptionPeriod,
            familyShareable: product.isFamilyShareable,
            introductoryOffer: subscription.introductoryOffer
        )
    }

    private func mapSubscriptionUnit(_ unit: Product.SubscriptionPeriod.Unit) -> SubscriptionPeriod.Unit {
        switch unit {
        case .day:
            return .day
        case .week:
            return .week
        case .month:
            return .month
        case .year:
            return .year
        @unknown default:
            return .month
        }
    }

    private func mapStoreKitError(_ error: Error) -> AppError {
        if let storeKitError = error as? StoreKitError {
            switch storeKitError {
            case .networkError:
                return .networkError("StoreKit network error")
            case .systemError:
                return .systemError("StoreKit system error")
            case .notAvailableInStorefront:
                return .productNotFound("Product not available in current storefront")
            case .notEntitled:
                return .unauthorized
            case .userCancelled:
                return .operationNotAllowed("User cancelled")
            case .unknown:
                return .unknownError("Unknown StoreKit error")
            case .unsupported:
                return .storeKitNotAvailable
            @unknown default:
                return .unknownError("StoreKit error: \(storeKitError.localizedDescription)")
            }
        }

        if let productError = error as? Product.PurchaseError {
            switch productError {
            case .productUnavailable:
                return .storeKitNotAvailable
            case .purchaseNotAllowed:
                return .operationNotAllowed("Purchase not allowed")
            case .ineligibleForOffer:
                return .operationNotAllowed("Ineligible for offer")
            case .invalidOfferIdentifier:
                return .invalidOperation("Invalid offer identifier")
            case .invalidOfferPrice:
                return .invalidOperation("Invalid offer price")
            case .invalidQuantity:
                return .invalidOperation("Invalid quantity")
            case .invalidOfferSignature:
                return .systemError("Invalid offer signature")
            case .missingOfferParameters:
                return .missingRequiredField("Missing offer parameters")
            @unknown default:
                return .purchaseFailed(productError.localizedDescription)
            }
        }

        return .unknownError(error.localizedDescription)
    }
}