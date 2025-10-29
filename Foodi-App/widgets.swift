//
//  Widgets.swift
//  Foodi
//
//  Created by Francisco Campa on 10/12/25.
//

import SwiftUI
import MapKit

// MARK: - Widget Button
struct WidgetButton: View {
    var type: WidgetType
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.85))
                    .shadow(radius: 3)
                    .frame(height: 300) // taller widgets
                
                Text(type.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

// MARK: - Widget Detail View (Expanded full-screen views)
struct WidgetDetailView: View {
    var type: WidgetType
    @Binding var selectedWidget: WidgetType?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack {
                switch type {
                case .feed:
                    FeedView()
                        .padding(.top, 20)

                case .leaderboard:
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("🏆 Top Foodies Leaderboard")
                                .font(.largeTitle).bold()
                                .padding(.top, 20)
                            
                            ForEach(1..<11) { rank in
                                HStack {
                                    Text("#\(rank)").font(.title3).bold()
                                    Spacer()
                                    Text("User \(rank)").font(.headline)
                                    Spacer()
                                    Text("\(Int.random(in: 100...500)) pts")
                                        .font(.subheadline).foregroundColor(.gray)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange.opacity(0.2))
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                case .map:
                    // Full interactive map view
                    ZStack {
                        MapWidgetView()
                            .ignoresSafeArea(edges: .bottom)
                            .padding(.top, 40) // moves MapWidgetView down slightly
                    }
                }
            }
            
            // Close button
            Button(action: { selectedWidget = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}

// MARK: - Widget Type Enum
enum WidgetType: String, Identifiable {
    case feed, leaderboard, map
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .feed: return "Feed"
        case .leaderboard: return "Leaderboard (Top Foodies)"
        case .map: return "Map"
        }
    }
}
