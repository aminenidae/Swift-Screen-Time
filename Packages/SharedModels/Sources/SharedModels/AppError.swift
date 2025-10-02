import Foundation

/// Error types for the ScreenTimeRewards application
public enum AppError: LocalizedError, Equatable {
    // Network and connectivity errors
    case networkUnavailable
    case networkTimeout
    case networkError(String)
    
    // CloudKit errors
    case cloudKitNotAvailable
    case cloudKitRecordNotFound
    case cloudKitSaveError(String)
    case cloudKitFetchError(String)
    case cloudKitDeleteError(String)
    case cloudKitZoneError(String)
    
    // Data validation errors
    case invalidData(String)
    case missingRequiredField(String)
    case dataValidationError(String)
    
    // Authentication errors
    case unauthorized
    case authenticationFailed
    case familyAccessDenied
    
    // Business logic errors
    case insufficientPoints
    case invalidOperation(String)
    case operationNotAllowed(String)
    
    // StoreKit errors
    case storeKitNotAvailable
    case productNotFound(String)
    case purchaseFailed(String)
    case transactionNotFound
    case subscriptionExpired
    case restoreFailed(String)

    // System errors
    case systemError(String)
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network settings and try again."
        case .networkTimeout:
            return "The request timed out. Please try again."
        case .networkError(let message):
            return "Network error: \(message)"
        case .cloudKitNotAvailable:
            return "iCloud is not available. Please sign in to iCloud and try again."
        case .cloudKitRecordNotFound:
            return "The requested data was not found."
        case .cloudKitSaveError(let message):
            return "Failed to save data: \(message)"
        case .cloudKitFetchError(let message):
            return "Failed to fetch data: \(message)"
        case .cloudKitDeleteError(let message):
            return "Failed to delete data: \(message)"
        case .cloudKitZoneError(let message):
            return "CloudKit zone error: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .missingRequiredField(let field):
            return "Required field is missing: \(field)"
        case .dataValidationError(let message):
            return "Data validation error: \(message)"
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .authenticationFailed:
            return "Authentication failed. Please try signing in again."
        case .familyAccessDenied:
            return "Access to family data denied."
        case .insufficientPoints:
            return "Not enough points for this reward."
        case .invalidOperation(let message):
            return "Invalid operation: \(message)"
        case .operationNotAllowed(let message):
            return "Operation not allowed: \(message)"
        case .storeKitNotAvailable:
            return "In-app purchases are not available. Please check your settings and try again."
        case .productNotFound(let productId):
            return "Subscription product '\(productId)' not found."
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .transactionNotFound:
            return "Transaction not found or already processed."
        case .subscriptionExpired:
            return "Your subscription has expired. Please renew to continue."
        case .restoreFailed(let message):
            return "Failed to restore purchases: \(message)"
        case .systemError(let message):
            return "System error: \(message)"
        case .unknownError(let message):
            return "An unknown error occurred: \(message)"
        }
    }

    /// Recovery suggestions for users to resolve the error
    public var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Try connecting to Wi-Fi or cellular data, then retry the operation."
        case .networkTimeout:
            return "Check your internet connection and try again. If the problem persists, try again later."
        case .networkError:
            return "Check your internet connection and try again."
        case .cloudKitNotAvailable:
            return "Go to Settings > [Your Name] > iCloud and make sure you're signed in."
        case .cloudKitRecordNotFound:
            return "The data may have been deleted or moved. Try refreshing the screen."
        case .cloudKitSaveError:
            return "Check your iCloud storage space and internet connection, then try saving again."
        case .cloudKitFetchError:
            return "Check your internet connection and try refreshing the data."
        case .cloudKitDeleteError:
            return "Check your internet connection and try again."
        case .cloudKitZoneError:
            return "Try signing out and back into iCloud, then restart the app."
        case .invalidData:
            return "Please check the information you entered and try again."
        case .missingRequiredField:
            return "Please fill in all required fields and try again."
        case .dataValidationError:
            return "Please check your input and make sure all information is correct."
        case .unauthorized:
            return "Contact a parent or administrator for access."
        case .authenticationFailed:
            return "Try signing out and back into your account."
        case .familyAccessDenied:
            return "Make sure you're part of the family sharing group and have the necessary permissions."
        case .insufficientPoints:
            return "Complete more learning activities to earn the required points."
        case .invalidOperation:
            return "This action cannot be completed right now. Please try again later."
        case .operationNotAllowed:
            return "This operation is not permitted in the current context."
        case .storeKitNotAvailable:
            return "Go to Settings > Screen Time > Content & Privacy Restrictions and make sure In-App Purchases are allowed."
        case .productNotFound:
            return "Please check your internet connection and try again. If the problem persists, contact support."
        case .purchaseFailed:
            return "Check your payment method in App Store settings and try again."
        case .transactionNotFound:
            return "If you completed a purchase, try restarting the app to refresh your subscription status."
        case .subscriptionExpired:
            return "Tap 'Subscribe' to renew your subscription and continue using premium features."
        case .restoreFailed:
            return "Make sure you're signed in with the same Apple ID used for the original purchase."
        case .systemError:
            return "Please restart the app and try again. If the problem persists, contact support."
        case .unknownError:
            return "Please try again. If the problem continues, restart the app or contact support."
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .networkUnavailable:
            return "Network unavailable"
        case .networkTimeout:
            return "Network timeout"
        case .networkError:
            return "Network error"
        case .cloudKitNotAvailable:
            return "CloudKit unavailable"
        case .cloudKitRecordNotFound:
            return "Record not found"
        case .cloudKitSaveError:
            return "Save failed"
        case .cloudKitFetchError:
            return "Fetch failed"
        case .cloudKitDeleteError:
            return "Delete failed"
        case .cloudKitZoneError:
            return "Zone error"
        case .invalidData:
            return "Invalid data"
        case .missingRequiredField:
            return "Missing required field"
        case .dataValidationError:
            return "Data validation error"
        case .unauthorized:
            return "Unauthorized"
        case .authenticationFailed:
            return "Authentication failed"
        case .familyAccessDenied:
            return "Family access denied"
        case .insufficientPoints:
            return "Insufficient points"
        case .invalidOperation:
            return "Invalid operation"
        case .operationNotAllowed:
            return "Operation not allowed"
        case .storeKitNotAvailable:
            return "StoreKit unavailable"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        case .transactionNotFound:
            return "Transaction not found"
        case .subscriptionExpired:
            return "Subscription expired"
        case .restoreFailed:
            return "Restore failed"
        case .systemError:
            return "System error"
        case .unknownError:
            return "Unknown error"
        }
    }
}