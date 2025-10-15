//
//  RootContainer.swift
//  Foodi
//
//  Created by Tyler Hedberg on 10/13/25.
//

import Foundation
import SwiftUI

enum Route: Hashable { case settings, profile }

struct RootContainer: View {
    var body: some View {
        NavigationStack {
            HomeView()
                .toolbar {
                    // Title aligned LEFT using the principal slot
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Text("Foodi")
                                .font(.title3).bold()
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                        }
                    }

                    // Right-side buttons
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        NavigationLink(value: Route.settings) {
                            Image(systemName: "gearshape").imageScale(.large)
                        }
                        NavigationLink(value: Route.profile) {
                            Image(systemName: "person.crop.circle").imageScale(.large)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .settings: SettingsView()
                    case .profile:  ProfileView()
                    }
                }
        }
    }
}
