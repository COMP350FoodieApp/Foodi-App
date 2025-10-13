//
//  HomeView.swift
//  Foodi
//
//  Created by Francisco Campa on 10/12/25.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedWidget: WidgetType? = nil
    @State private var showPostSheet = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Top row: Feed + Leaderboard
                HStack(spacing: 20) {
                    WidgetButton(type: .feed) {
                        selectedWidget = .feed
                    }
                    WidgetButton(type: .leaderboard) {
                        selectedWidget = .leaderboard
                    }
                }
                
                // Compact map widget
                ZStack {
                    MapWidgetView() // full map with search bar
                        .disabled(true) // prevent interaction in compact view
                        .frame(height: 350)
                        .cornerRadius(16)
                        .shadow(radius: 3)
                    
                    // Tap overlay
                    Rectangle()
                        .foregroundColor(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedWidget = .map
                        }
                }
                .padding(.top, 10)
            }
            .padding()
            
            // Floating Post Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showPostSheet.toggle() }) {
                        ZStack {
                            Circle()
                                .fill(Color.orange)
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
        }
        // Full-screen view for widget expansion
        .fullScreenCover(item: $selectedWidget) { widget in
            WidgetDetailView(type: widget, selectedWidget: $selectedWidget)
        }
    }
}
