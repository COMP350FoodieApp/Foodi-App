//
//  ProfileView.swift
//  Foodi
//
//  Created by Tyler Hedberg on 10/13/25.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill").font(.system(size: 80))
            Text("Your Name").font(.headline)
            Text("Short bio goes here").foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Profile")
    }
}
