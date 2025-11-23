//
//  RestaurantProfileView.swift
//  Foodi
//
//  Created by Francisco Campa on 11/23/25.
//

import SwiftUI
import MapKit

struct RestaurantProfileView: View {
    let restaurantName: String
    let coordinate: CLLocationCoordinate2D
    
    @State private var posts: [Post] = []
    @State private var averageRating: Double = 0.0
    @State private var hours: [String] = []   // for API later
    @State private var showFullMap = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // ------------------------------------------------------
                // MARK: TAP-TO-OPEN MAP
                // ------------------------------------------------------
                ZStack {
                    Map {
                        Marker(restaurantName, coordinate: coordinate)
                    }
                    .frame(height: 220)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Transparent tap layer to capture tap
                    Rectangle()
                        .foregroundColor(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showFullMap = true
                        }
                }
                .sheet(isPresented: $showFullMap) {
                    RestaurantMapSheet(
                        target: coordinate,
                        restaurantName: restaurantName
                    )
                }
                
                
                // ------------------------------------------------------
                // MARK: RESTAURANT NAME + AVG RATING
                // ------------------------------------------------------
                VStack(spacing: 6) {
                    Text(restaurantName)
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text("\(String(format: "%.1f", averageRating)) / 5")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                
                // ------------------------------------------------------
                // MARK: HOURS SECTION (future API support)
                // ------------------------------------------------------
                if !hours.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hours")
                            .font(.headline)
                        
                        ForEach(hours, id: \.self) { hour in
                            Text(hour)
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                
                // ------------------------------------------------------
                // MARK: POSTS ABOUT THIS RESTAURANT
                // ------------------------------------------------------
                VStack(alignment: .leading, spacing: 12) {
                    Text("Posts")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    if posts.isEmpty {
                        Text("No posts yet for this restaurant.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(posts) { post in
                            PostRowView(post: post)
                        }
                    }
                }
            }
        }
        .onAppear {
            // Load posts for this restaurant
            PostManager.shared.fetchPosts(forRestaurant: restaurantName) { fetched in
                posts = fetched
                
                if !fetched.isEmpty {
                    averageRating =
                        fetched
                            .compactMap { $0.rating }
                            .reduce(0, +) / Double(fetched.count)
                }
            }
        }
        .navigationTitle(restaurantName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
