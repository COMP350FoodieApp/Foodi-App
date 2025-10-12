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
                HStack(spacing: 20) {
                    WidgetButton(type: .feed, action: { selectedWidget = .feed })
                    WidgetButton(type: .leaderboard, action: { selectedWidget = .leaderboard })
                }
                
                WidgetButton(type: .map, action: { selectedWidget = .map })
                    .frame(maxWidth: .infinity)
            }
            .padding()
            
            // Floating Post Button 🍔
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
        // Opens detail view when a widget is tapped
        .fullScreenCover(item: $selectedWidget) { widget in
            WidgetDetailView(type: widget, selectedWidget: $selectedWidget)
        }
    }
}
