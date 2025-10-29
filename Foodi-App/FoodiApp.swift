//
//  FoodiApp.swift
//  Foodi
//
//  Created by Francisco Campa on 9/22/25.
//

import SwiftUI
import FirebaseCore

@main
struct FoodiApp: App {
    init() {
      FirebaseApp.configure()
      print("APP ▶︎ FoodiApp.init() ran")
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView() // Launches to splash screen first
        }
    }
}
