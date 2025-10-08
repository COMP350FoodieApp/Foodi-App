//
//  Untitled.swift
//  Foodi
//
//  Created by d-rod on 10/8/25.
//

import SwiftUI

// MARK: - Splash Screen
struct SplashView: View {
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea() // Foodi color theme
            Text("Foodi")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.white)
                .opacity(isActive ? 0 : 1)
                .animation(.easeInOut(duration: 1.0), value: isActive)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            HomeView()
        }
    }
}

// MARK: - Home Screen with Widgets
struct HomeView: View {
    @State private var selectedWidget: WidgetType? = nil
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Top row: 2 widgets
                HStack(spacing: 20) {
                    WidgetButton(type: .topLeft, action: { selectedWidget = .topLeft })
                    WidgetButton(type: .topRight, action: { selectedWidget = .topRight })
                }
                // Bottom wide widget
                WidgetButton(type: .bottom, action: { selectedWidget = .bottom })
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        // Opens detail view when a widget is tapped
        .fullScreenCover(item: $selectedWidget) { widget in
            WidgetDetailView(type: widget, selectedWidget: $selectedWidget)
        }
    }
}

// MARK: - Widget Button
struct WidgetButton: View {
    var type: WidgetType
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.85)) // Match Foodi color
                    .frame(height: type == .bottom ? 180 : 120)
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
            
            // Exit (X) button
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
    case topLeft, topRight, bottom
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .topLeft: return "Widget 1"
        case .topRight: return "Widget 2"
        case .bottom: return "Widget 3"
        }
    }
}
