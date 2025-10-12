//
//  Widgets.swift
//  Foodi
//
//  Created by Francisco Campa on 10/12/25.
//

import SwiftUI

// MARK: - Widget Button
struct WidgetButton: View {
    var type: WidgetType
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.85))
                    .frame(height: type == .map ? 180 : 120)
                    .shadow(radius: 3)
                
                Text(type.title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Widget Detail View
struct WidgetDetailView: View {
    var type: WidgetType
    @Binding var selectedWidget: WidgetType?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.ignoresSafeArea()
            
            VStack {
                Spacer()
                Text("\(type.title) Page")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
            }
            
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

