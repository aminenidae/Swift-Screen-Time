import Foundation
import FamilyControls
import DeviceActivity
import SharedModels
import CloudKitService
import FamilyControlsKit
import Combine

/// Service responsible for tracking time spent in educational apps and coordinating point calculations
@available(iOS 15.0, macOS 12.0, *)
public class PointTrackingService: NSObject, ObservableObject {
    // MARK: - Properties

    public static let shared = PointTrackingService()

    private let calculationEngine: PointCalculationEngine
    private let usageRepository: CloudKitUsageSessionRepository
    private let pointRepository: CloudKitPointTransactionRepository
    private let deviceActivityService = DeviceActivityService.shared
    private var cancellables = Set<AnyCancellable>()

    // Currently tracked educational apps with their point values
    private var educationalApps: [String: Int] = [:] // bundleID: pointsPerHour
    private var activeChildProfiles: Set<String> = []

    // Publishers for reactive updates
    @Published public var pointsEarned: PointTransaction?
    @Published public var trackingStatus = false

    // MARK: - Initialization

    public override init() {
        self.calculationEngine = PointCalculationEngine()
        self.usageRepository = CloudKitUsageSessionRepository()
        self.pointRepository = CloudKitPointTransactionRepository()
        super.init()
        setupMonitoring()
    }

    public init(
        calculationEngine: PointCalculationEngine = PointCalculationEngine(),
        usageRepository: CloudKitUsageSessionRepository,
        pointRepository: CloudKitPointTransactionRepository
    ) {
        self.calculationEngine = calculationEngine
        self.usageRepository = usageRepository
        self.pointRepository = pointRepository
        super.init()
        setupMonitoring()
    }

    /// Sets up monitoring for device activity events
    private func setupMonitoring() {
        // Subscribe to DeviceActivityService events
        deviceActivityService.$sessionEnded
            .compactMap { $0 }
            .sink { [weak self] session in
                self?.processCompletedSession(session)
            }
            .store(in: &cancellables)

        deviceActivityService.$sessionStarted
            .compactMap { $0 }
            .sink { [weak self] session in
                self?.handleSessionStarted(session)
            }
            .store(in: &cancellables)
    }
    
    /// Starts tracking for a specific child profile
    /// - Parameter childProfileID: The ID of the child profile to track
    public func startTracking(for childProfileID: String) async throws {
        activeChildProfiles.insert(childProfileID)

        // Get educational apps for this child
        await loadEducationalApps(for: childProfileID)

        // Start device activity monitoring if not already started
        if !trackingStatus {
            let educationalAppTokens = Set(educationalApps.keys.map { ApplicationToken($0) })
            try await deviceActivityService.startMonitoring(educationalApps: educationalAppTokens)
            trackingStatus = true
        }

        print("✅ PointTrackingService: Started tracking for child \(childProfileID)")
    }

    /// Stops tracking for a specific child profile
    /// - Parameter childProfileID: The ID of the child profile to stop tracking
    public func stopTracking(for childProfileID: String) {
        activeChildProfiles.remove(childProfileID)

        // If no more children are being tracked, stop device monitoring
        if activeChildProfiles.isEmpty {
            deviceActivityService.stopMonitoring()
            trackingStatus = false
        }

        print("🛑 PointTrackingService: Stopped tracking for child \(childProfileID)")
    }

    /// Configures educational apps and their point values
    /// - Parameter apps: Dictionary of bundle ID to points per hour
    public func configureEducationalApps(_ apps: [String: Int]) {
        educationalApps = apps
        print("📚 PointTrackingService: Configured \(apps.count) educational apps")
    }

    /// Processes a completed usage session and calculates points
    /// - Parameter session: The completed usage session
    private func processCompletedSession(_ session: UsageSession) {
        // Only process sessions for tracked children and educational apps
        guard activeChildProfiles.contains(session.childProfileID),
              let pointsPerHour = educationalApps[session.appBundleID],
              session.duration > 60 // Minimum 1 minute session
        else {
            return
        }

        Task {
            await processSessionAndEarnPoints(session, pointsPerHour: pointsPerHour)
        }
    }

    /// Handles session started event
    /// - Parameter session: The started session
    private func handleSessionStarted(_ session: UsageSession) {
        guard activeChildProfiles.contains(session.childProfileID),
              educationalApps.keys.contains(session.appBundleID) else {
            return
        }

        print("🎯 PointTrackingService: Educational app session started - \(session.appBundleID)")
    }

    /// Processes session and awards points
    /// - Parameters:
    ///   - session: The usage session
    ///   - pointsPerHour: Points per hour for this app
    private func processSessionAndEarnPoints(_ session: UsageSession, pointsPerHour: Int) async {
        do {
            // Calculate points based on the session
            let points = calculationEngine.calculatePoints(for: session, pointsPerHour: pointsPerHour)

            // Only award points if session was long enough and points > 0
            guard points > 0 else { return }

            // Save the usage session
            _ = try await usageRepository.createSession(session)

            // Create and save point transaction
            let transaction = PointTransaction(
                id: UUID().uuidString,
                childProfileID: session.childProfileID,
                points: points,
                reason: "Learning time: \(session.appBundleID) for \(Int(session.duration/60)) minutes",
                timestamp: Date()
            )

            _ = try await pointRepository.createTransaction(transaction)

            // Notify about points earned
            DispatchQueue.main.async {
                self.pointsEarned = transaction
            }

            print("⭐ PointTrackingService: Awarded \(points) points to child \(session.childProfileID)")

        } catch {
            print("❌ PointTrackingService: Error processing session: \(error)")
        }
    }

    /// Loads educational apps configuration for a child
    /// - Parameter childProfileID: The child profile ID
    private func loadEducationalApps(for childProfileID: String) async {
        // TODO: Load from CloudKit or UserDefaults
        // For now, use default educational apps
        let defaultEducationalApps = [
            "com.duolingo.DuolingoMobile": 30,
            "com.apple.mobilenotes": 15,
            "com.apple.iBooks": 25,
            "com.khanacademy.Khan-Academy": 40,
            "com.apple.calculator": 10,
            "com.apple.Pages": 20,
            "com.apple.Numbers": 20,
            "com.apple.Keynote": 20
        ]

        educationalApps.merge(defaultEducationalApps) { _, new in new }
        print("📚 PointTrackingService: Loaded \(educationalApps.count) educational apps for child \(childProfileID)")
    }
    
    /// Handles app switching events
    /// - Parameters:
    ///   - fromApp: The app being switched from
    ///   - toApp: The app being switched to
    public func handleAppSwitch(from fromApp: String, to toApp: String) {
        print("🔄 PointTrackingService: App switch from \(fromApp) to \(toApp)")

        // The DeviceActivityService handles the actual session end/start
        // This method can be used for additional logic if needed
    }

    /// Handles device sleep/wake events
    /// - Parameter isSleeping: Whether the device is entering sleep mode
    public func handleDeviceSleepState(_ isSleeping: Bool) {
        if isSleeping {
            deviceActivityService.handleDeviceSleep()
            print("💤 PointTrackingService: Device sleeping - ending all sessions")
        } else {
            deviceActivityService.handleDeviceWake()
            print("☀️ PointTrackingService: Device waking")
        }
    }

    /// Ensures tracking data persists across app restarts
    public func ensurePersistence() {
        // Save current configuration to UserDefaults
        UserDefaults.standard.set(Array(activeChildProfiles), forKey: "activeChildProfiles")
        UserDefaults.standard.set(educationalApps, forKey: "educationalApps")
        UserDefaults.standard.set(trackingStatus, forKey: "trackingStatus")

        print("💾 PointTrackingService: Persistence ensured")
    }

    /// Restores tracking state from persistent storage
    public func restoreState() async {
        // Restore active child profiles
        if let savedProfiles = UserDefaults.standard.array(forKey: "activeChildProfiles") as? [String] {
            activeChildProfiles = Set(savedProfiles)
        }

        // Restore educational apps configuration
        if let savedApps = UserDefaults.standard.dictionary(forKey: "educationalApps") as? [String: Int] {
            educationalApps = savedApps
        }

        // Restore tracking status and restart if needed
        let savedTrackingStatus = UserDefaults.standard.bool(forKey: "trackingStatus")
        if savedTrackingStatus && !activeChildProfiles.isEmpty {
            do {
                let educationalAppTokens = Set(educationalApps.keys.map { ApplicationToken($0) })
                try await deviceActivityService.startMonitoring(educationalApps: educationalAppTokens)
                trackingStatus = true
                print("🔄 PointTrackingService: Restored tracking state for \(activeChildProfiles.count) children")
            } catch {
                print("❌ PointTrackingService: Failed to restore tracking state: \(error)")
            }
        }
    }

    /// Gets current points balance for a child
    /// - Parameter childProfileID: The child profile ID
    /// - Returns: Current points balance
    public func getCurrentPoints(for childProfileID: String) async throws -> Int {
        // TODO: Implement actual points calculation from transactions
        // For now, return a mock value
        return 150
    }

    /// Gets usage statistics for a child
    /// - Parameters:
    ///   - childProfileID: The child profile ID
    ///   - days: Number of days to look back
    /// - Returns: Dictionary of app bundle ID to total usage time
    public func getUsageStatistics(for childProfileID: String, days: Int = 7) async throws -> [String: TimeInterval] {
        // TODO: Implement actual usage statistics from sessions
        // For now, return mock data
        return [
            "com.duolingo.DuolingoMobile": 3600, // 1 hour
            "com.khanacademy.Khan-Academy": 1800, // 30 minutes
            "com.apple.iBooks": 2400 // 40 minutes
        ]
    }
}