import Foundation
import SharedModels
import Combine
import CloudKitService

@available(iOS 15.0, macOS 12.0, *)
public class ParentDashboardViewModel: ObservableObject {
    @Published public var childProfiles: [ChildProfile] = []
    @Published public var appCategorizations: [AppCategorization] = []
    @Published public var showAlert = false
    @Published public var alertMessage = ""
    
    private let familyID: UUID
    private let userID: String
    private let cloudKitService: CloudKitService
    private let coordinationService: ParentCoordinationService
    private let changeDetectionService: ChangeDetectionService
    private var cancellables: Set<AnyCancellable> = []
    
    public init(familyID: UUID, userID: String) {
        self.familyID = familyID
        self.userID = userID
        self.cloudKitService = CloudKitService.shared
        self.coordinationService = ParentCoordinationService.shared
        self.changeDetectionService = ChangeDetectionService.shared
        
        setupCoordinationSubscriptions()
        loadInitialData()
    }
    
    /// Sets up subscriptions for coordination events
    private func setupCoordinationSubscriptions() {
        // Create coordination zone
        Task {
            try? await coordinationService.createParentCoordinationZone(for: familyID)
        }
        
        // Create coordination subscription
        Task {
            try? await coordinationService.createCoordinationSubscription(for: familyID, excluding: userID)
        }
        
        // In a real implementation, we would subscribe to coordination events
        // For now, we'll simulate this with a timer
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // Simulate checking for updates
                self.checkForCoordinationUpdates()
            }
            .store(in: &cancellables)
    }
    
    /// Loads initial data for the dashboard
    private func loadInitialData() {
        // Load child profiles, app categorizations, etc.
        // This would typically fetch from CloudKitService repositories
        print("Loading initial data for family: \(familyID)")
    }
    
    /// Checks for coordination updates
    private func checkForCoordinationUpdates() {
        // In a real implementation, this would be triggered by
        // coordination events from the ParentCoordinationService
        print("Checking for coordination updates...")
    }
    
    /// Handles a coordination event
    public func handleCoordinationEvent(_ event: ParentCoordinationEvent) {
        DispatchQueue.main.async {
            switch event.eventType {
            case .appCategorizationChanged:
                self.showAlert(message: "Co-parent updated app categorization")
                self.refreshAppCategorizations()
            case .childProfileModified:
                self.showAlert(message: "Co-parent modified child profile")
                self.refreshChildProfiles()
            case .pointsAdjusted:
                self.showAlert(message: "Co-parent adjusted points")
                self.refreshChildProfiles()
            case .rewardRedeemed:
                self.showAlert(message: "Co-parent redeemed a reward")
                // Refresh relevant data
                break
            case .settingsUpdated:
                self.showAlert(message: "Co-parent updated settings")
                // Refresh settings
                break
            case .usageSessionChanged:
                self.showAlert(message: "Co-parent usage session changed")
                // Refresh usage data
                break
            }
        }
    }
    
    /// Shows an alert with a message
    private func showAlert(message: String) {
        self.alertMessage = message
        self.showAlert = true
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showAlert = false
        }
    }
    
    /// Refreshes app categorizations
    private func refreshAppCategorizations() {
        // In a real implementation, this would fetch updated app categorizations
        print("Refreshing app categorizations...")
    }
    
    /// Refreshes child profiles
    private func refreshChildProfiles() {
        // In a real implementation, this would fetch updated child profiles
        print("Refreshing child profiles...")
    }
    
    /// Updates a child's point balance
    public func updateChildPoints(childID: String, newBalance: Int) {
        // Find the child profile and update its balance
        if let index = childProfiles.firstIndex(where: { $0.id == childID }),
           var child = childProfiles[safe: index] {
            let oldBalance = child.pointBalance
            child.pointBalance = newBalance
            
            // Update in CloudKit
            Task {
                do {
                    // This would call the appropriate CloudKitService method
                    // try await cloudKitService.updateChild(child)
                    
                    // Publish the change
                    try await changeDetectionService.publishPointsAdjustment(
                        childID: childID,
                        newBalance: newBalance,
                        oldBalance: oldBalance,
                        familyID: familyID,
                        userID: userID
                    )
                } catch {
                    print("Error updating child points: \(error)")
                }
            }
        }
    }
    
    /// Updates an app categorization
    public func updateAppCategorization(_ categorization: AppCategorization) {
        Task {
            do {
                // This would call the appropriate CloudKitService method
                // try await cloudKitService.updateAppCategorization(categorization)
                
                // Publish the change
                try await changeDetectionService.publishAppCategorizationChange(
                    categorization,
                    familyID: familyID,
                    userID: userID
                )
            } catch {
                print("Error updating app categorization: \(error)")
            }
        }
    }
}

// Extension to safely access array elements
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}