import Foundation
@testable import RewardCore
import SharedModels

class MockAnalyticsConsentRepository: AnalyticsConsentRepository, @unchecked Sendable {
    var savedConsent: AnalyticsConsent?
    var consents: [String: AnalyticsConsent] = [:]
    
    func saveConsent(_ consent: AnalyticsConsent) async throws {
        savedConsent = consent
        consents[consent.familyID] = consent
    }
    
    func fetchConsent(for familyID: String) async throws -> AnalyticsConsent? {
        return consents[familyID]
    }
    
    func deleteConsent(for familyID: String) async throws {
        consents.removeValue(forKey: familyID)
    }
}