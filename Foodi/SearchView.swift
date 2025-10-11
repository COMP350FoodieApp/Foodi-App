//
//  SearchView.swift
//  Foodi
//
//  Created by Tyler Hedberg on 10/11/25.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [String] = []

    var body: some View {
        VStack {
            TextField("Search restaurants, dishes, or tags", text: $query)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit(performSearch)
                .padding(.top)
                .padding(.horizontal)

            if results.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(results, id: \.self) { item in
                    Text(item).onTapGesture { dismiss() }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var emptyState: some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView(
                "Search Foodi",
                systemImage: "fork.knife",
                description: Text("Try “ramen”, “tacos”, or a restaurant name")
            )
        } else {
            VStack(spacing: 8) {
                Image(systemName: "fork.knife").font(.largeTitle)
                Text("Search Foodi").font(.headline)
                Text("Try “ramen”, “tacos”, or a restaurant name")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
        }
    }

    private func performSearch() {
        let sample = ["Joe’s Taco Truck", "Sushi Garden", "Ramen House", "Vegan Deli"]
        results = sample.filter { $0.localizedCaseInsensitiveContains(query) }
    }
}
