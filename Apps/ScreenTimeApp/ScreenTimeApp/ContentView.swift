//
//  ContentView.swift
//  ScreenTimeApp
//
//  Created by Amine Nidae on 2025-09-25.
//

import SwiftUI
import CoreData
import FamilyControls
import Combine

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("userRole") private var userRole: String = "parent"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                if userRole == "child" {
                    EnhancedChildMainView()
                } else {
                    AuthenticatedParentView {
                        ParentMainView()
                    }
                }
            } else {
                OnboardingView()
            }
        }
    }
}

// MARK: - Authentication Wrapper
struct AuthenticatedParentView<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
    }
}

// MARK: - Forward Declarations for Views to be Modularized

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif