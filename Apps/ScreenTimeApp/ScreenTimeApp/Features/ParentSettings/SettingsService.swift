import Foundation
import FamilyControlsKit
import Combine

/// Service to manage settings state and preferences
class SettingsService: ObservableObject {
    static let shared = SettingsService()
    
    @Published var isFamilyControlsEnabled: Bool = false
    @Published var selectedChild: FamilyMemberInfo? = nil
    @Published var isDarkModeEnabled: Bool = false
    
    // Learning app settings
    @Published var pointsPerMinute: Double = 1.0
    @Published var weekendMultiplier: Double = 1.5
    @Published var dailyStreakBonus: Int = 5
    @Published var weeklyGoalBonus: Int = 50
    
    // Time limit settings
    @Published var educationalAppsLimit: Int = 120
    @Published var entertainmentAppsLimit: Int = 60
    @Published var socialAppsLimit: Int = 30
    @Published var gamingAppsLimit: Int = 45
    
    // Reward app settings
    @Published var entertainmentAppCost: Int = 10
    @Published var bonusScreenTimeCost: Int = 5
    
    private init() {
        loadSettings()
    }
    
    /// Load settings from UserDefaults
    private func loadSettings() {
        isDarkModeEnabled = UserDefaults.standard.bool(forKey: "isDarkModeEnabled")
        pointsPerMinute = UserDefaults.standard.double(forKey: "pointsPerMinute")
        weekendMultiplier = UserDefaults.standard.double(forKey: "weekendMultiplier")
        dailyStreakBonus = UserDefaults.standard.integer(forKey: "dailyStreakBonus")
        weeklyGoalBonus = UserDefaults.standard.integer(forKey: "weeklyGoalBonus")
        educationalAppsLimit = UserDefaults.standard.integer(forKey: "educationalAppsLimit")
        entertainmentAppsLimit = UserDefaults.standard.integer(forKey: "entertainmentAppsLimit")
        socialAppsLimit = UserDefaults.standard.integer(forKey: "socialAppsLimit")
        gamingAppsLimit = UserDefaults.standard.integer(forKey: "gamingAppsLimit")
        entertainmentAppCost = UserDefaults.standard.integer(forKey: "entertainmentAppCost")
        bonusScreenTimeCost = UserDefaults.standard.integer(forKey: "bonusScreenTimeCost")
        
        // Set default values if not set
        if pointsPerMinute == 0 { pointsPerMinute = 1.0 }
        if weekendMultiplier == 0 { weekendMultiplier = 1.5 }
        if entertainmentAppCost == 0 { entertainmentAppCost = 10 }
        if bonusScreenTimeCost == 0 { bonusScreenTimeCost = 5 }
    }
    
    /// Save settings to UserDefaults
    func saveSettings() {
        UserDefaults.standard.set(isDarkModeEnabled, forKey: "isDarkModeEnabled")
        UserDefaults.standard.set(pointsPerMinute, forKey: "pointsPerMinute")
        UserDefaults.standard.set(weekendMultiplier, forKey: "weekendMultiplier")
        UserDefaults.standard.set(dailyStreakBonus, forKey: "dailyStreakBonus")
        UserDefaults.standard.set(weeklyGoalBonus, forKey: "weeklyGoalBonus")
        UserDefaults.standard.set(educationalAppsLimit, forKey: "educationalAppsLimit")
        UserDefaults.standard.set(entertainmentAppsLimit, forKey: "entertainmentAppsLimit")
        UserDefaults.standard.set(socialAppsLimit, forKey: "socialAppsLimit")
        UserDefaults.standard.set(gamingAppsLimit, forKey: "gamingAppsLimit")
        UserDefaults.standard.set(entertainmentAppCost, forKey: "entertainmentAppCost")
        UserDefaults.standard.set(bonusScreenTimeCost, forKey: "bonusScreenTimeCost")
    }
    
    /// Reset all settings to default values
    func resetToDefaults() {
        isDarkModeEnabled = false
        pointsPerMinute = 1.0
        weekendMultiplier = 1.5
        dailyStreakBonus = 5
        weeklyGoalBonus = 50
        educationalAppsLimit = 120
        entertainmentAppsLimit = 60
        socialAppsLimit = 30
        gamingAppsLimit = 45
        entertainmentAppCost = 10
        bonusScreenTimeCost = 5
        saveSettings()
    }
    
    /// Update family controls status
    func updateFamilyControlsStatus(_ isEnabled: Bool) {
        isFamilyControlsEnabled = isEnabled
    }
    
    /// Select a child for child-specific settings
    func selectChild(_ child: FamilyMemberInfo?) {
        selectedChild = child
    }
}