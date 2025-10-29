//
//  RootContainer.swift
//  Foodi
//
//  Created by Tyler Hedberg on 10/13/25.
//
import SwiftUI

enum Route: Hashable { case settings, profile }

struct RootContainer: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .toolbar(.hidden, for: .navigationBar)

                .safeAreaInset(edge: .top) {
                    FoodiHeader(
                        bannerColor: Color(red: 0x4D/255, green: 0x84/255, blue: 0xF7/255), // #4d84f7
                        titleSize: 22,
                        titleWeight: .bold,              
                        onProfile:  { path.append(.profile) },
                        onSettings: { path.append(.settings) }
                    )
                }

                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .settings: SettingsView()
                    case .profile:  ProfileView()
                    }
                }
        }
    }
}
