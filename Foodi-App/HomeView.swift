//
//  HomeView.swift
//  Foodi
//
//  Edited by d-rod on 10/29/25.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedWidget: WidgetType? = nil
    @State private var showPostSheet = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 10) {
                // Top row: Feed + Leaderboard
                HStack(spacing: 20) {
                    // Feed Widget
                    Button(action: { selectedWidget = .feed }) {
                        VStack(spacing: 10) {
                            Image(systemName: "text.bubble.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                            Text("Feed")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("See what others are posting")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: 180, minHeight: 220)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                    }
                    
                    // Leaderboard Widget
                    Button(action: { selectedWidget = .leaderboard }) {
                        VStack(spacing: 10) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.yellow)
                            Text("Leaderboard")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Top Foodies this week")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: 180, minHeight: 220)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                    }
                }
                .padding(.top, 30)
                
                // Compact map widget
                ZStack {
                    MapWidgetView() // full map with search bar
                        .disabled(true) // prevent interaction in compact view
                        .frame(width: 380, height: 350)
                        .cornerRadius(16)
                        .shadow(radius: 3)
                        .clipped()
                    
                    // Tap overlay (limited to map area)
                    Rectangle()
                        .foregroundColor(.clear)
                        .contentShape(Rectangle())
                        .frame(width: 380, height: 350)
                        .cornerRadius(16)
                        .onTapGesture {
                            selectedWidget = .map
                        }

                }
                .padding(.top, 10)
            }
            .padding(.top, 30)
            .padding(.bottom, 100)
            
            // Floating Post Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showPostSheet.toggle() }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 70, height: 70)
                                .shadow(radius: 5)
                            
                            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .sheet(isPresented: $showPostSheet) {
                        PostView()
                    }
                }
            }
            
            FloatingSearchUsersButton()
        }
        // Full-screen view for widget expansion
        .fullScreenCover(item: $selectedWidget) { widget in
            WidgetDetailView(type: widget, selectedWidget: $selectedWidget)
        }
    }
}

// Floating Search Users Button (Bottom Left)
struct FloatingSearchUsersButton: View {
    @State private var showUserSearch = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                // Search Users Button (Bottom-Left)
                Button(action: {
                    showUserSearch.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 5)

                        // Combined person + magnifying glass icon
                        ZStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .offset(x: -3, y: 0)

                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .offset(x: 8, y: 4)
                        }
                        .foregroundColor(.white)
                    }
                }
                // ✅ Perfect alignment with post button
                .padding(.bottom, 38)
                .padding(.leading, 15)
                // ✅ Present search view with NavigationStack (fixes white screen issue)
                .sheet(isPresented: $showUserSearch) {
                    NavigationStack {
                        UserSearchView()
                    }
                }

                Spacer()
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}


