//
//  FoodiApp.swift
//  Foodi
//
//  Created by Tyler Hedberg on 10/11/25.
//

import SwiftUI
// import FirebaseCore  // <- enable later if you add Firebase

@main
struct FoodiApp: App {
    init() {
        // FirebaseApp.configure() // <- later
    }

    var body: some Scene {
        WindowGroup {
            ContentView()   // your root view
        }
    }
}
