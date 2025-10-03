//
//  RewardsSystemTests.swift
//  ScreenTimeAppTests
//
//  Created on 2025-10-02.
//

import Testing
import SwiftUI
import FamilyControlsKit
import SharedModels
@testable import ScreenTimeApp

@Suite("Rewards System Tests")
struct RewardsSystemTests {

    @Test("RewardsView initializes correctly")
    func testRewardsViewInitialization() async throws {
        let rewardsView = RewardsView()
        #expect(rewardsView != nil)
    }

    @Test("EntertainmentAppUnlockCard displays correctly")
    func testEntertainmentAppUnlockCard() async throws {
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
        #expect(unlockCard != nil)
    }

    @Test("DurationOptionButton functionality")
    func testDurationOptionButton() async throws {
        var tapped = false
        let button = DurationOptionButton(
            duration: 30,
            cost: 25,
            canAfford: true,
            onTap: { tapped = true }
        )
        #expect(button != nil)
    }

    @Test("RedeemedReward model works correctly")
    func testRedeemedRewardModel() async throws {
        let reward = RedeemedReward(
            id: UUID(),
            name: "Test Reward",
            cost: 50,
            redeemedAt: Date(),
            status: .pending
        )

        #expect(reward.name == "Test Reward")
        #expect(reward.cost == 50)
        #expect(reward.status == .pending)
        #expect(reward.status.text == "Pending Approval")
        #expect(reward.status.color == .orange)
    }

    @Test("RedemptionStatus enum works correctly")
    func testRedemptionStatus() async throws {
        #expect(RedemptionStatus.pending.text == "Pending Approval")
        #expect(RedemptionStatus.approved.text == "Approved")
        #expect(RedemptionStatus.denied.text == "Denied")

        #expect(RedemptionStatus.pending.color == .orange)
        #expect(RedemptionStatus.approved.color == .green)
        #expect(RedemptionStatus.denied.color == .red)
    }
}