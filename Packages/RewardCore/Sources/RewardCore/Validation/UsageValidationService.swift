import Foundation
import SharedModels

// MARK: - Validation Protocol and Types

@available(iOS 15.0, macOS 12.0, *)
public protocol UsageValidator {
    func validate(session: UsageSession, familySettings: FamilySettings) async -> ValidationAlgorithmResult
    var validatorName: String { get }
}

/// Result from a single validation algorithm
@available(iOS 15.0, macOS 12.0, *)
public struct ValidationAlgorithmResult {
    public let isValid: Bool
    public let violation: ValidationViolation?
    
    public init(isValid: Bool, violation: ValidationViolation?) {
        self.isValid = isValid
        self.violation = violation
    }
}

/// Types of validation violations
@available(iOS 15.0, macOS 12.0, *)
public enum ValidationViolation {
    case timeBased
    case appCategory
    case frequency
}

/// Service responsible for validating usage sessions to prevent gaming of the reward system
@available(iOS 15.0, macOS 12.0, *)
public class UsageValidationService {
    private let validationAlgorithms: [UsageValidator]
    private let familySettingsRepository: FamilySettingsRepository
    private let parentNotificationService: ParentNotificationService?

    public init(
        familySettingsRepository: FamilySettingsRepository,
        parentNotificationService: ParentNotificationService? = nil
    ) {
        self.validationAlgorithms = [
            EngagementValidator(),
            RapidSwitchingValidator(),
            TimingPatternValidator()
        ]
        self.familySettingsRepository = familySettingsRepository
        self.parentNotificationService = parentNotificationService
    }

    /// Validate a usage session against all validation algorithms
    /// - Parameter session: The session to validate
    /// - Returns: Validation result with details
    public func validateSession(_ session: UsageSession) async throws -> ValidationResult {
        // Get family settings for context
        let settings = try await familySettingsRepository.fetchSettings(for: session.childProfileID)
        
        // If no settings found, create default settings
        let familySettings = settings ?? FamilySettings(
            id: UUID().uuidString,
            familyID: session.childProfileID,
            dailyTimeLimit: nil,
            bedtimeStart: nil,
            bedtimeEnd: nil,
            contentRestrictions: [:]
        )
        
        // Run all validation algorithms
        var results: [ValidationAlgorithmResult] = []
        for validator in validationAlgorithms {
            let result = await validator.validate(session: session, familySettings: familySettings)
            results.append(result)
        }
        
        // Aggregate results
        let isValid = results.allSatisfy { $0.isValid }
        let violations = results.compactMap { $0.violation }
        
        return ValidationResult(
            isValid: isValid,
            violations: violations,
            confidenceScore: calculateConfidenceScore(from: results)
        )
    }
    
    /// Calculate overall confidence score from individual validation results
    private func calculateConfidenceScore(from results: [ValidationAlgorithmResult]) -> Double {
        guard !results.isEmpty else { return 1.0 }
        
        let validCount = results.filter { $0.isValid }.count
        return Double(validCount) / Double(results.count)
    }
}

// MARK: - Supporting Types

@available(iOS 15.0, macOS 12.0, *)
public extension UsageValidationService {
    struct ValidationResult {
        public let isValid: Bool
        public let violations: [ValidationViolation]
        public let confidenceScore: Double
        
        public init(isValid: Bool, violations: [ValidationViolation], confidenceScore: Double) {
            self.isValid = isValid
            self.violations = violations
            self.confidenceScore = confidenceScore
        }
    }
}