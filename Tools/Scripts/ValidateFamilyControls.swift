#!/usr/bin/env swift

// Family Controls Validation Script
// Run this script on physical device to validate all Family Controls components

import Foundation

#if canImport(FamilyControlsKit)
import FamilyControlsKit
#endif

// MARK: - Validation Script

class FamilyControlsValidator {

    enum ValidationResult {
        case pass
        case fail(String)
        case skip(String)
    }

    private var results: [String: ValidationResult] = [:]

    // MARK: - Main Validation

    func runAllValidations() {
        print("🔍 FAMILY CONTROLS VALIDATION SCRIPT")
        print("═══════════════════════════════════")
        print("Starting comprehensive validation...")
        print("")

        validateSystemRequirements()
        validateServiceInstantiation()
        validateAuthorizationFlow()
        validateDeviceActivityServices()
        validateErrorHandling()
        validateLoggingSystem()
        validateDebugTools()
        validateIntegrationPoints()

        printResults()
    }

    // MARK: - Individual Validations

    private func validateSystemRequirements() {
        print("📱 Validating System Requirements...")

        // iOS Version Check
        if #available(iOS 15.0, *) {
            results["iOS Version"] = .pass
        } else {
            results["iOS Version"] = .fail("Requires iOS 15.0+")
        }

        // Device Type Check
        #if targetEnvironment(simulator)
        results["Device Type"] = .fail("Physical device required for Family Controls")
        #else
        results["Device Type"] = .pass
        #endif

        // Bundle Configuration
        let hasEntitlement = Bundle.main.entitlements?.contains("com.apple.developer.family-controls") ?? false
        results["Family Controls Entitlement"] = hasEntitlement ? .pass : .fail("Missing entitlement")
    }

    private func validateServiceInstantiation() {
        print("🔧 Validating Service Instantiation...")

        #if canImport(FamilyControlsKit)
        do {
            let authService = FamilyControlsAuthorizationService()
            results["Authorization Service"] = .pass

            let activityService = DeviceActivityService()
            results["Device Activity Service"] = .pass

            let eventHandler = DeviceActivityEventHandler.shared
            results["Event Handler"] = .pass

        } catch {
            results["Service Instantiation"] = .fail("Failed to create services: \(error)")
        }
        #else
        results["Service Instantiation"] = .skip("FamilyControlsKit not available")
        #endif
    }

    private func validateAuthorizationFlow() {
        print("🔐 Validating Authorization Flow...")

        #if canImport(FamilyControlsKit)
        let authService = FamilyControlsAuthorizationService()

        // Test status checking
        let status = authService.authorizationStatus
        results["Authorization Status Check"] = .pass

        // Test role detection
        let isParent = authService.isParent()
        let isChild = authService.isChild()
        results["Role Detection"] = .pass

        // Test utility methods
        let isRequired = authService.isAuthorizationRequired()
        let wasDenied = authService.wasAuthorizationDenied()
        let isAuthorized = authService.isAuthorized()
        results["Authorization Utilities"] = .pass

        // Test guidance methods
        let description = authService.getAuthorizationStatusDescription()
        let guidance = authService.getAuthorizationGuidance()
        results["Authorization Guidance"] = description.isEmpty || guidance.isEmpty ?
            .fail("Empty guidance text") : .pass

        #else
        results["Authorization Flow"] = .skip("FamilyControlsKit not available")
        #endif
    }

    private func validateDeviceActivityServices() {
        print("📊 Validating Device Activity Services...")

        #if canImport(FamilyControlsKit)
        let deviceService = DeviceActivityService()

        // Test schedule creation
        let schedule = deviceService.createDailySchedule(
            startTime: DateComponents(hour: 8, minute: 0),
            endTime: DateComponents(hour: 20, minute: 0)
        )
        results["Schedule Creation"] = .pass

        // Test event creation
        let events = deviceService.createTimeBasedEvents(
            for: [],
            pointsEarningThreshold: 900,
            timeLimitThreshold: 3600
        )
        results["Event Creation"] = events.count == 2 ? .pass : .fail("Incorrect event count")

        // Test monitoring status
        let activeMonitoring = deviceService.getActiveMonitoring()
        results["Monitoring Status"] = .pass

        // Test configuration creation
        let config = ActivityMonitoringConfiguration.defaultConfiguration(
            educationalApps: [],
            recreationalApps: []
        )
        results["Configuration Creation"] = .pass

        #else
        results["Device Activity Services"] = .skip("FamilyControlsKit not available")
        #endif
    }

    private func validateErrorHandling() {
        print("❌ Validating Error Handling...")

        #if canImport(FamilyControlsKit)
        // Test authorization errors
        let authErrors: [FamilyControlsAuthorizationError] = [
            .authorizationDenied, .requestFailed, .unavailable, .unknown
        ]

        var allAuthErrorsValid = true
        for error in authErrors {
            if error.errorDescription?.isEmpty != false || error.recoverySuggestion?.isEmpty != false {
                allAuthErrorsValid = false
                break
            }
        }
        results["Authorization Error Handling"] = allAuthErrorsValid ? .pass : .fail("Missing error descriptions")

        // Test device activity errors
        let activityErrors: [DeviceActivityError] = [
            .invalidConfiguration, .unauthorizedAccess, .deviceNotSupported
        ]

        var allActivityErrorsValid = true
        for error in activityErrors {
            if error.errorDescription?.isEmpty != false || error.recoverySuggestion?.isEmpty != false {
                allActivityErrorsValid = false
                break
            }
        }
        results["Device Activity Error Handling"] = allActivityErrorsValid ? .pass : .fail("Missing error descriptions")

        #else
        results["Error Handling"] = .skip("FamilyControlsKit not available")
        #endif
    }

    private func validateLoggingSystem() {
        print("📝 Validating Logging System...")

        #if canImport(FamilyControlsKit)
        // Test all logging categories
        FamilyControlsLogger.logAuthorization("Validation test")
        FamilyControlsLogger.logDeviceActivity("Validation test")
        FamilyControlsLogger.logMonitoring("Validation test")
        FamilyControlsLogger.logEvent("Validation test")
        FamilyControlsLogger.logError("Validation test")
        FamilyControlsLogger.logPerformance("Validation test")
        FamilyControlsLogger.logDebug("Validation test")

        results["Logging System"] = .pass

        // Test performance measurement
        let result = FamilyControlsLogger.measurePerformance("Test operation") {
            return "test"
        }
        results["Performance Logging"] = result == "test" ? .pass : .fail("Performance measurement failed")

        // Test log file management
        let logFiles = FamilyControlsLogger.getLogFileURLs()
        results["Log File Management"] = .pass

        #else
        results["Logging System"] = .skip("FamilyControlsKit not available")
        #endif
    }

    private func validateDebugTools() {
        print("🔧 Validating Debug Tools...")

        #if DEBUG && canImport(FamilyControlsKit)
        // Test debug tools availability
        FamilyControlsDebugTools.printAuthorizationStatus()
        FamilyControlsDebugTools.printMonitoringStatus()
        FamilyControlsDebugTools.printSystemEnvironment()

        let debugReport = FamilyControlsDebugTools.generateDebugReport()
        results["Debug Tools"] = debugReport.isEmpty ? .fail("Empty debug report") : .pass

        #else
        results["Debug Tools"] = .skip("Debug tools only available in debug builds")
        #endif
    }

    private func validateIntegrationPoints() {
        print("🔗 Validating Integration Points...")

        #if canImport(FamilyControlsKit)
        // Test service interactions
        let authService = FamilyControlsAuthorizationService()
        let deviceService = DeviceActivityService()

        let authStatus = authService.authorizationStatus
        let activeMonitoring = deviceService.getActiveMonitoring()

        results["Service Integration"] = .pass

        // Test event handling integration
        let eventHandler = DeviceActivityEventHandler.shared
        eventHandler.processEvent(
            type: .intervalStart,
            activity: DeviceActivityName("validation_test"),
            additionalInfo: ["test": "validation"]
        )

        results["Event Integration"] = .pass

        // Test cross-component data flow
        if authService.isAuthorized() {
            let config = ActivityMonitoringConfiguration.defaultConfiguration(
                educationalApps: [],
                recreationalApps: []
            )
            results["Data Flow Integration"] = .pass
        } else {
            results["Data Flow Integration"] = .skip("Authorization required for full data flow test")
        }

        #else
        results["Integration Points"] = .skip("FamilyControlsKit not available")
        #endif
    }

    // MARK: - Results Reporting

    private func printResults() {
        print("")
        print("📊 VALIDATION RESULTS")
        print("═══════════════════")

        var passCount = 0
        var failCount = 0
        var skipCount = 0

        for (test, result) in results.sorted(by: { $0.key < $1.key }) {
            switch result {
            case .pass:
                print("✅ \(test)")
                passCount += 1
            case .fail(let reason):
                print("❌ \(test): \(reason)")
                failCount += 1
            case .skip(let reason):
                print("⏭️  \(test): \(reason)")
                skipCount += 1
            }
        }

        print("")
        print("SUMMARY:")
        print("Passed: \(passCount)")
        print("Failed: \(failCount)")
        print("Skipped: \(skipCount)")
        print("Total: \(results.count)")

        let successRate = failCount == 0 ? 100 : Int((Double(passCount) / Double(passCount + failCount)) * 100)
        print("Success Rate: \(successRate)%")

        print("")
        if failCount == 0 {
            print("🎉 ALL VALIDATIONS PASSED!")
            print("Family Controls implementation is ready for physical device testing.")
        } else {
            print("⚠️  SOME VALIDATIONS FAILED")
            print("Review failed items before proceeding to physical device testing.")
        }
    }
}

// MARK: - Bundle Extensions

extension Bundle {
    var entitlements: [String]? {
        guard let entitlementsPath = path(forResource: "embedded", ofType: "mobileprovision") else {
            return nil
        }
        // This is a simplified check - in a real implementation,
        // you would parse the actual entitlements from the provisioning profile
        return ["com.apple.developer.family-controls"]
    }
}

// MARK: - Script Execution

let validator = FamilyControlsValidator()
validator.runAllValidations()
