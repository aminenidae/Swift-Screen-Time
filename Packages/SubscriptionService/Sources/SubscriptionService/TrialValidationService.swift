import Foundation
import SharedModels

/// Service responsible for server-side trial validation and audit logging
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class TrialValidationService: ObservableObject {
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: AppError?

    private let familyRepository: FamilyRepository

    public init(familyRepository: FamilyRepository) {
        self.familyRepository = familyRepository
    }

    /// Validate trial status and detect bypass attempts
    /// - Parameter familyID: The family ID to validate
    /// - Returns: Validation result with audit information
    public func validateTrialStatus(for familyID: String) async -> TrialValidationResult {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            // Fetch family data for validation
            guard let family = try await familyRepository.fetchFamily(id: familyID) else {
                await logAuditEvent(.validation(
                    familyID: familyID,
                    result: .failed(reason: "Family not found"),
                    timestamp: Date(),
                    clientInfo: getCurrentClientInfo()
                ))
                return .invalid(reason: .familyNotFound)
            }

            // Perform comprehensive validation
            let validationResult = await performComprehensiveValidation(family: family)

            // Log audit event
            await logAuditEvent(.validation(
                familyID: familyID,
                result: validationResult.auditResult,
                timestamp: Date(),
                clientInfo: getCurrentClientInfo()
            ))

            return validationResult

        } catch {
            await updateError(error as? AppError ?? .systemError(error.localizedDescription))
            return .invalid(reason: .systemError)
        }
    }

    /// Validate trial activation request
    /// - Parameter request: Trial activation request
    /// - Returns: Validation result for activation
    public func validateTrialActivation(_ request: TrialActivationRequest) async -> TrialActivationValidationResult {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        // Perform multiple validation checks
        let checks = await performActivationValidationChecks(request)

        // Log activation attempt
        await logAuditEvent(.activationAttempt(
            familyID: request.familyID,
            userID: request.userID,
            clientInfo: request.clientInfo,
            validationChecks: checks,
            timestamp: Date()
        ))

        // Determine overall result
        let isValid = checks.allSatisfy { $0.passed }
        let result: TrialActivationValidationResult = isValid ? .approved : .denied(reasons: checks.compactMap { $0.passed ? nil : $0.failureReason })

        return result
    }

    /// Detect and report trial bypass attempts
    /// - Parameter familyID: The family ID to check
    /// - Returns: Bypass detection result
    public func detectTrialBypass(for familyID: String) async -> BypassDetectionResult {
        do {
            guard let family = try await familyRepository.fetchFamily(id: familyID) else {
                return .noBypassDetected
            }

            var suspiciousActivities: [SuspiciousActivity] = []

            // Check for data inconsistencies
            if let metadata = family.subscriptionMetadata {
                // Check for impossible trial dates
                if let trialStart = metadata.trialStartDate,
                   let trialEnd = metadata.trialEndDate,
                   trialStart > trialEnd {
                    suspiciousActivities.append(.impossibleTrialDates(start: trialStart, end: trialEnd))
                }

                // Check for future trial start dates
                if let trialStart = metadata.trialStartDate,
                   trialStart > Date() {
                    suspiciousActivities.append(.futureTrialStartDate(date: trialStart))
                }

                // Check for multiple trial usage indicators
                if metadata.hasUsedTrial && metadata.trialStartDate == nil {
                    suspiciousActivities.append(.inconsistentTrialState)
                }
            }

            // Check for rapid family creation patterns (would require additional tracking)
            // This is a placeholder for more sophisticated bypass detection

            if suspiciousActivities.isEmpty {
                return .noBypassDetected
            } else {
                // Log bypass attempt
                await logAuditEvent(.bypassAttempt(
                    familyID: familyID,
                    activities: suspiciousActivities,
                    timestamp: Date(),
                    clientInfo: getCurrentClientInfo()
                ))

                return .bypassDetected(activities: suspiciousActivities)
            }

        } catch {
            await updateError(error as? AppError ?? .systemError(error.localizedDescription))
            return .error(message: "Failed to detect bypass attempts")
        }
    }

    /// Get audit log for a family
    /// - Parameter familyID: The family ID
    /// - Returns: Audit log entries
    public func getAuditLog(for familyID: String) async -> [AuditEvent] {
        // In a real implementation, this would query CloudKit for audit records
        // For now, return empty array as this would require additional CloudKit schema
        return []
    }

    // MARK: - Private Methods

    private func performComprehensiveValidation(family: Family) async -> TrialValidationResult {
        var validationIssues: [ValidationIssue] = []

        guard let metadata = family.subscriptionMetadata else {
            return .valid(issues: [])
        }

        // Validate trial dates
        if let trialStart = metadata.trialStartDate,
           let trialEnd = metadata.trialEndDate {

            // Check if trial period is reasonable (should be 14 days)
            let trialDuration = Calendar.current.dateComponents([.day], from: trialStart, to: trialEnd).day ?? 0
            if trialDuration != 14 {
                validationIssues.append(.invalidTrialDuration(expected: 14, actual: trialDuration))
            }

            // Check if trial is in the past but marked as active
            if trialEnd < Date() && metadata.isActive {
                validationIssues.append(.expiredTrialMarkedActive)
            }
        }

        // Validate subscription state consistency
        if metadata.isActive &&
           metadata.subscriptionStartDate == nil &&
           metadata.trialStartDate == nil {
            validationIssues.append(.activeWithoutSubscriptionOrTrial)
        }

        // Return validation result
        if validationIssues.isEmpty {
            return .valid(issues: [])
        } else {
            return .invalid(reason: .validationFailure(issues: validationIssues))
        }
    }

    private func performActivationValidationChecks(_ request: TrialActivationRequest) async -> [ValidationCheck] {
        var checks: [ValidationCheck] = []

        // Check 1: Family exists and is accessible
        do {
            let family = try await familyRepository.fetchFamily(id: request.familyID)
            checks.append(ValidationCheck(
                name: "FamilyExists",
                passed: family != nil,
                failureReason: family == nil ? "Family not found" : nil
            ))

            // Check 2: Family hasn't already used trial
            if let family = family {
                let hasUsedTrial = family.subscriptionMetadata?.hasUsedTrial ?? false
                checks.append(ValidationCheck(
                    name: "TrialNotUsed",
                    passed: !hasUsedTrial,
                    failureReason: hasUsedTrial ? "Trial already used" : nil
                ))

                // Check 3: No active subscription
                let hasActiveSubscription = family.subscriptionMetadata?.isActive ?? false
                checks.append(ValidationCheck(
                    name: "NoActiveSubscription",
                    passed: !hasActiveSubscription,
                    failureReason: hasActiveSubscription ? "Active subscription exists" : nil
                ))
            }
        } catch {
            checks.append(ValidationCheck(
                name: "FamilyAccessible",
                passed: false,
                failureReason: "Error accessing family data"
            ))
        }

        // Check 4: Request timing validation (not too frequent)
        checks.append(ValidationCheck(
            name: "RequestTiming",
            passed: true, // Placeholder - would check against rate limiting
            failureReason: nil
        ))

        // Check 5: Client information validation
        let hasValidClientInfo = !request.clientInfo.deviceID.isEmpty && !request.clientInfo.appVersion.isEmpty
        checks.append(ValidationCheck(
            name: "ValidClientInfo",
            passed: hasValidClientInfo,
            failureReason: hasValidClientInfo ? nil : "Invalid client information"
        ))

        return checks
    }

    private func logAuditEvent(_ event: AuditEvent) async {
        // In a real implementation, this would save to CloudKit audit table
        // For now, we'll just log locally for development
        print("AUDIT: \(event)")

        // Future implementation would use CloudKit to store:
        // - Event type and details
        // - Timestamp
        // - Family/User IDs
        // - Client information
        // - Validation results
    }

    private func getCurrentClientInfo() -> ClientInfo {
        return ClientInfo(
            deviceID: "current-device-id", // Would get from device
            appVersion: "1.0.0", // Would get from bundle
            osVersion: "iOS 15.0", // Would get from system
            buildNumber: "1"
        )
    }

    private func updateError(_ error: AppError) async {
        await MainActor.run {
            self.error = error
        }
    }
}

// MARK: - Supporting Types

public enum TrialValidationResult {
    case valid(issues: [ValidationIssue])
    case invalid(reason: ValidationFailureReason)

    var auditResult: AuditValidationResult {
        switch self {
        case .valid(let issues):
            return .passed(issues: issues)
        case .invalid(let reason):
            return .failed(reason: "\(reason)")
        }
    }
}

public enum ValidationFailureReason {
    case familyNotFound
    case validationFailure(issues: [ValidationIssue])
    case systemError
}

public enum ValidationIssue {
    case invalidTrialDuration(expected: Int, actual: Int)
    case expiredTrialMarkedActive
    case activeWithoutSubscriptionOrTrial
    case inconsistentDates
}

public enum TrialActivationValidationResult {
    case approved
    case denied(reasons: [String])
}

public struct ValidationCheck {
    public let name: String
    public let passed: Bool
    public let failureReason: String?

    public init(name: String, passed: Bool, failureReason: String?) {
        self.name = name
        self.passed = passed
        self.failureReason = failureReason
    }
}

public struct TrialActivationRequest {
    public let familyID: String
    public let userID: String
    public let clientInfo: ClientInfo
    public let requestedAt: Date

    public init(familyID: String, userID: String, clientInfo: ClientInfo, requestedAt: Date = Date()) {
        self.familyID = familyID
        self.userID = userID
        self.clientInfo = clientInfo
        self.requestedAt = requestedAt
    }
}

public struct ClientInfo {
    public let deviceID: String
    public let appVersion: String
    public let osVersion: String
    public let buildNumber: String

    public init(deviceID: String, appVersion: String, osVersion: String, buildNumber: String) {
        self.deviceID = deviceID
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.buildNumber = buildNumber
    }
}

public enum BypassDetectionResult {
    case noBypassDetected
    case bypassDetected(activities: [SuspiciousActivity])
    case error(message: String)
}

public enum SuspiciousActivity {
    case impossibleTrialDates(start: Date, end: Date)
    case futureTrialStartDate(date: Date)
    case inconsistentTrialState
    case rapidFamilyCreation
    case duplicateDeviceID
}

public enum AuditEvent {
    case validation(familyID: String, result: AuditValidationResult, timestamp: Date, clientInfo: ClientInfo)
    case activationAttempt(familyID: String, userID: String, clientInfo: ClientInfo, validationChecks: [ValidationCheck], timestamp: Date)
    case bypassAttempt(familyID: String, activities: [SuspiciousActivity], timestamp: Date, clientInfo: ClientInfo)
}

public enum AuditValidationResult {
    case passed(issues: [ValidationIssue])
    case failed(reason: String)
}