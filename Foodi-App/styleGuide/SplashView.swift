//
//  SplashView.swift
//  Foodi
//
//  Created by d-rod on 10/8/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            Color.foodiBlue.ignoresSafeArea()   // was Color.blue
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
           RootContainer()
        }
    }
}

