import Foundation
import StoreKit
import SharedModels
import UserNotifications

@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class SubscriptionStatusService: ObservableObject {
    @Published public private(set) var currentStatus: SharedModels.SubscriptionStatus?
    @Published public private(set) var currentEntitlement: SubscriptionEntitlementInfo?
    @Published public private(set) var autoRenewStatus: Bool = false
    @Published public private(set) var expirationDate: Date?
    @Published public private(set) var gracePeriodExpirationDate: Date?
    @Published public private(set) var isMonitoring: Bool = false

    private var transactionListenerTask: Task<Void, Error>?
    private let gracePeriodDays: Int = 16 // Grace period for billing retry
    private let cloudKitSync: SubscriptionCloudKitSync
    private let renewalMonitor: SubscriptionRenewalMonitor
    private let cancellationDetector: SubscriptionCancellationDetector

    // Callback for CloudKit synchronization
    public var onStatusChanged: ((SharedModels.SubscriptionStatus) -> Void)?
    public var familyID: String?

    public init(familyID: String? = nil) {
        self.familyID = familyID
        self.cloudKitSync = SubscriptionCloudKitSync()
        self.renewalMonitor = SubscriptionRenewalMonitor()
        self.cancellationDetector = SubscriptionCancellationDetector()
    }

    /// Start monitoring subscription status changes via Transaction.currentEntitlements
    public func startMonitoring() async {
        await MainActor.run {
            isMonitoring = true
        }

        // Listen for transaction updates
        transactionListenerTask = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try result.payloadValue
                    await self.processTransactionUpdate(transaction)
                } catch {
                    print("Transaction update error: \(error)")
                }
            }
        }

        // Initial status check
        await updateCurrentStatus()

        // Start renewal monitoring
        await renewalMonitor.startMonitoring()
    }

    /// Stop monitoring subscription status changes
    public func stopMonitoring() {
        transactionListenerTask?.cancel()
        transactionListenerTask = nil
        isMonitoring = false
    }

    /// Force refresh of current subscription status
    public func refreshStatus() async {
        await updateCurrentStatus()
    }

    /// Get current active subscription entitlement
    public func getCurrentEntitlement() -> SubscriptionEntitlementInfo? {
        return currentEntitlement
    }

    /// Get renewal monitor for accessing renewal status and callbacks
    public var renewalMonitorInstance: SubscriptionRenewalMonitor {
        return renewalMonitor
    }

    /// Get cancellation detector for accessing cancellation status and callbacks
    public var cancellationDetectorInstance: SubscriptionCancellationDetector {
        return cancellationDetector
    }

    // MARK: - Private Methods

    private func updateCurrentStatus() async {
        var latestEntitlement: SubscriptionEntitlementInfo?
        var latestTransaction: Transaction?

        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try result.payloadValue

                // Only process subscription transactions for our products
                guard ProductIdentifiers.allProducts.contains(transaction.productID),
                      let expirationDate = transaction.expirationDate else {
                    continue
                }

                // Find the latest transaction
                if latestTransaction == nil || expirationDate > (latestTransaction?.expirationDate ?? Date.distantPast) {
                    latestTransaction = transaction
                    latestEntitlement = SubscriptionEntitlementInfo(
                        productID: transaction.productID,
                        purchaseDate: transaction.purchaseDate,
                        expirationDate: expirationDate,
                        isAutoRenewOn: transaction.isUpgraded == false,
                        willAutoRenew: transaction.revocationDate == nil
                    )
                }
            } catch {
                print("Error processing transaction: \(error)")
            }
        }

        await MainActor.run {
            currentEntitlement = latestEntitlement
            expirationDate = latestTransaction?.expirationDate
            autoRenewStatus = latestTransaction?.revocationDate == nil

            // Determine subscription status
            let newStatus = determineSubscriptionStatus(
                from: latestTransaction,
                entitlement: latestEntitlement
            )

            if currentStatus != newStatus {
                let oldStatus = currentStatus
                currentStatus = newStatus

                if let status = newStatus {
                    onStatusChanged?(status)

                    // Sync to CloudKit if family ID is set
                    if let familyID = familyID {
                        Task {
                            do {
                                try await cloudKitSync.syncSubscriptionStatus(status, forFamily: familyID)
                            } catch {
                                print("Failed to sync subscription status to CloudKit: \(error)")
                            }
                        }
                    }

                    // Process renewal monitoring
                    Task {
                        await renewalMonitor.processStatusChange(
                            from: oldStatus,
                            to: status,
                            entitlement: latestEntitlement
                        )
                    }

                    // Process cancellation detection
                    Task {
                        await cancellationDetector.processStatusChange(
                            from: oldStatus,
                            to: status,
                            entitlement: latestEntitlement
                        )

                        // Check if we should show resubscription offer
                        await cancellationDetector.presentResubscriptionOfferIfNeeded(entitlement: latestEntitlement)
                    }
                }
            }
        }
    }

    private func processTransactionUpdate(_ transaction: Transaction) async {
        // Only process our subscription products
        guard ProductIdentifiers.allProducts.contains(transaction.productID) else {
            return
        }

        await updateCurrentStatus()
    }

    private func determineSubscriptionStatus(
        from transaction: Transaction?,
        entitlement: SubscriptionEntitlementInfo?
    ) -> SharedModels.SubscriptionStatus? {

        guard let transaction = transaction else {
            return nil
        }

        let now = Date()

        // Check if transaction was revoked (refunded)
        if transaction.revocationDate != nil {
            return .revoked
        }

        // Check expiration
        guard let expirationDate = transaction.expirationDate else {
            return nil
        }

        // Determine if we're in trial period
        let isInTrialPeriod = transaction.offerType == .introductory

        if now <= expirationDate {
            // Subscription is current
            return isInTrialPeriod ? .trial : .active
        } else {
            // Subscription has expired, check grace period
            let gracePeriodEnd = Calendar.current.date(byAdding: .day, value: gracePeriodDays, to: expirationDate) ?? expirationDate

            if now <= gracePeriodEnd && transaction.revocationDate == nil {
                // In grace period with auto-renew enabled
                gracePeriodExpirationDate = gracePeriodEnd
                return .gracePeriod
            } else {
                // Fully expired
                return .expired
            }
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }
}

// MARK: - Supporting Types

public struct SubscriptionEntitlementInfo: Codable {
    public let productID: String
    public let purchaseDate: Date
    public let expirationDate: Date
    public let isAutoRenewOn: Bool
    public let willAutoRenew: Bool

    public init(
        productID: String,
        purchaseDate: Date,
        expirationDate: Date,
        isAutoRenewOn: Bool,
        willAutoRenew: Bool
    ) {
        self.productID = productID
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.isAutoRenewOn = isAutoRenewOn
        self.willAutoRenew = willAutoRenew
    }

    /// Get subscription tier from product ID
    public var subscriptionTier: SubscriptionTier {
        switch productID {
        case ProductIdentifiers.oneChildMonthly, ProductIdentifiers.oneChildYearly:
            return .oneChild
        case ProductIdentifiers.twoChildMonthly, ProductIdentifiers.twoChildYearly:
            return .twoChildren
        default:
            return .oneChild
        }
    }

    /// Get billing period from product ID
    public var billingPeriod: BillingPeriod {
        switch productID {
        case ProductIdentifiers.oneChildYearly, ProductIdentifiers.twoChildYearly:
            return .yearly
        default:
            return .monthly
        }
    }

    /// Get next billing date
    public var nextBillingDate: Date? {
        return expirationDate
    }
}


public enum BillingPeriod: String, Codable, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"

    public var displayName: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }
}