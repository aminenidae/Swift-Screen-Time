import XCTest

class NotificationSettingsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testNotificationSettingsView() throws {
        // UI tests must be run on a physical device or simulator
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Settings
        let settingsTab = app.tabBars["Tab Bar"].buttons["Settings"]
        settingsTab.tap()
        
        // Wait for settings to load
        let settingsView = app.scrollViews["Settings View"]
        XCTAssertTrue(settingsView.waitForExistence(timeout: 5))
        
        // Find and tap on Notifications section
        let notificationsSection = settingsView.otherElements["Notifications Section"]
        if notificationsSection.exists {
            notificationsSection.tap()
        }
        
        // Check that notification settings view loads
        let notificationSettingsView = app.otherElements["Notification Settings View"]
        XCTAssertTrue(notificationSettingsView.waitForExistence(timeout: 5))
        
        // Check that master notification toggle exists
        let masterToggle = app.switches["Notifications Master Toggle"]
        XCTAssertTrue(masterToggle.exists)
        
        // Check that notification type toggles exist
        let pointsToggle = app.switches["Points Earned Toggle"]
        let goalToggle = app.switches["Goal Achieved Toggle"]
        
        if pointsToggle.exists && goalToggle.exists {
            // Test toggling a notification type
            let initialPointsState = pointsToggle.isOn
            pointsToggle.tap()
            XCTAssertNotEqual(pointsToggle.isOn, initialPointsState)
            
            // Toggle back
            pointsToggle.tap()
            XCTAssertEqual(pointsToggle.isOn, initialPointsState)
        }
        
        // Check that quiet hours pickers exist
        let startTimePicker = app.datePickers["Quiet Hours Start Time"]
        let endTimePicker = app.datePickers["Quiet Hours End Time"]
        
        XCTAssertTrue(startTimePicker.exists || endTimePicker.exists)
    }
    
    func testNotificationSettingsAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Settings
        let settingsTab = app.tabBars["Tab Bar"].buttons["Settings"]
        settingsTab.tap()
        
        // Wait for settings to load
        let settingsView = app.scrollViews["Settings View"]
        XCTAssertTrue(settingsView.waitForExistence(timeout: 5))
        
        // Check that notifications section is accessible
        let notificationsSection = settingsView.otherElements["Notifications Section"]
        if notificationsSection.exists {
            XCTAssertTrue(notificationsSection.isAccessibilityElement)
            XCTAssertEqual(notificationsSection.accessibilityLabel, "Notifications settings section")
        }
        
        // Tap on notifications section
        notificationsSection.tap()
        
        // Check that notification settings view is accessible
        let notificationSettingsView = app.otherElements["Notification Settings View"]
        XCTAssertTrue(notificationSettingsView.waitForExistence(timeout: 5))
        XCTAssertTrue(notificationSettingsView.isAccessibilityElement)
        
        // Check that toggles are accessible
        let masterToggle = app.switches["Notifications Master Toggle"]
        if masterToggle.exists {
            XCTAssertTrue(masterToggle.isAccessibilityElement)
            XCTAssertEqual(masterToggle.accessibilityLabel, "Enable or disable all notifications")
        }
    }
}