//
//  SettingsView.swift
//  Foodi
//
//  Created by Tyler Hedberg on 10/13/25.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("Account") { Text("Email"); Text("Password") }
            Section("Preferences") { Toggle("Notifications", isOn: .constant(true)) }
        }
        .navigationTitle("Settings")
    }
}
