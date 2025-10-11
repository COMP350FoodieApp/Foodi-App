//
//  ContentView.swift
//  Foodi
//
//  Created by Tyler Hedberg on 10/11/25.
//

import SwiftUI

enum Route: Hashable { case search }

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ExploreMapView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .search: SearchView()
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
