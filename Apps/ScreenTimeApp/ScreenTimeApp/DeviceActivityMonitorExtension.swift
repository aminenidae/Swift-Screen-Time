import Foundation
import DeviceActivity
import FamilyControlsKit

#if canImport(DeviceActivity) && !os(macOS)

/// DeviceActivityMonitor extension to handle device activity events
@available(iOS 15.0, *)
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    nonisolated override init() {
        super.init()
    }

    // MARK: - DeviceActivityMonitor Overrides

    nonisolated override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("📊 DeviceActivityMonitor: Interval started for \(activity)")
    }

    nonisolated override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("📊 DeviceActivityMonitor: Interval ended for \(activity)")
    }

    nonisolated override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        print("📊 DeviceActivityMonitor: Event \(event) reached threshold for \(activity)")
    }

    nonisolated override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        print("📊 DeviceActivityMonitor: Interval will start warning for \(activity)")
    }

    nonisolated override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        print("📊 DeviceActivityMonitor: Interval will end warning for \(activity)")
    }

    nonisolated override func eventWillReachThresholdWarning(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        print("📊 DeviceActivityMonitor: Event \(event) will reach threshold warning for \(activity)")
    }

    // MARK: - Custom Event Handling

    /// Handle application launch events
    /// - Parameters:
    ///   - bundleID: The bundle ID of the launched app
    ///   - childProfileID: The child profile ID
    private func handleApplicationLaunch(bundleID: String, childProfileID: String) {
        DeviceActivityService.shared.handleAppLaunch(bundleID, childProfileID: childProfileID)
    }

    /// Handle application exit events
    /// - Parameters:
    ///   - bundleID: The bundle ID of the exited app
    ///   - childProfileID: The child profile ID
    private func handleApplicationExit(bundleID: String, childProfileID: String) {
        DeviceActivityService.shared.handleAppExit(bundleID, childProfileID: childProfileID)
    }
}

#endif