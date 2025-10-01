//
//  ScreenTimeAppApp.swift
//  ScreenTimeApp
//
//  Created by Amine Nidae on 2025-09-25.
//

import SwiftUI
import CoreData
import FamilyControlsKit
import RewardCore
import DesignSystem
import SharedModels
import CloudKitService

@main
struct ScreenTimeAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
