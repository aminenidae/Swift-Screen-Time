//
//  ContentView.swift
//  ScreenTimeApp
//
//  Created by Amine Nidae on 2025-09-25.
//

import SwiftUI
import CoreData
import FamilyControls
import FamilyControlsKit
import DesignSystem
import SharedModels
import CloudKitService
import SubscriptionService
import RewardCore
import Combine

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("userRole") private var userRole: String = "parent"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                if userRole == "child" {
                    ChildMainView()
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

struct OnboardingView: View {
    @AppStorage("userRole") private var userRole: String = "parent"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Welcome to ScreenTime Rewards")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Transform screen time into learning time with our family-friendly reward system.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    Button("I'm a Parent") {
                        userRole = "parent"
                        hasCompletedOnboarding = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                    Button("I'm a Child") {
                        userRole = "child"
                        hasCompletedOnboarding = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Welcome")
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif