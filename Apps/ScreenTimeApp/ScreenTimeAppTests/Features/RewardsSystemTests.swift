//
//  RewardsSystemTests.swift
//  ScreenTimeAppTests
//
//  Created on 2025-10-02.
//

import XCTest
import SwiftUI
import FamilyControlsKit
import SharedModels
@testable import ScreenTimeApp

@available(iOS 15.0, *)
final class RewardsSystemTests: XCTestCase {

    func testRewardsViewInitialization() {
        let rewardsView = RewardsView()
        XCTAssertNotNil(rewardsView)
    }

    func testEntertainmentAppUnlockCard() {
        let mockApp = FamilyControlsKit.EntertainmentAppConfig(
            bundleID: "com.test.app",
            displayName: "Test App",
            pointsCostPer30Min: 25,
            pointsCostPer60Min: 45,
            isEnabled: true,
            parentConfiguredAt: Date()
        )

        let unlockCard = EntertainmentAppUnlockCard(
            app: mockApp,
            currentPoints: 100,
            isUnlocked: false,
            onUnlock: { _ in }
        )
        XCTAssertNotNil(unlockCard)
    }

    func testDurationOptionButton() {
        var tapped = false
        let button = DurationOptionButton(
            duration: 30,
            cost: 25,
            canAfford: true,
            onTap: { tapped = true }
        )
        XCTAssertNotNil(button)
    }

    func testRedeemedRewardModel() {
        let reward = RedeemedReward(
            id: UUID(),
            name: "Test Reward",
            cost: 50,
            redeemedAt: Date(),
            status: .pending
        )

        XCTAssertEqual(reward.name, "Test Reward")
        XCTAssertEqual(reward.cost, 50)
        XCTAssertEqual(reward.status, .pending)
        XCTAssertEqual(reward.status.text, "Pending Approval")
        XCTAssertEqual(reward.status.color, .orange)
    }

    func testRedemptionStatus() {
        XCTAssertEqual(RedemptionStatus.pending.text, "Pending Approval")
        XCTAssertEqual(RedemptionStatus.approved.text, "Approved")
        XCTAssertEqual(RedemptionStatus.denied.text, "Denied")

        XCTAssertEqual(RedemptionStatus.pending.color, .orange)
        XCTAssertEqual(RedemptionStatus.approved.color, .green)
        XCTAssertEqual(RedemptionStatus.denied.color, .red)
    }
}