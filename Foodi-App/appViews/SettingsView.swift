//
//  SettingsView.swift
//  Foodi
//
//  Created by David R on 11/04/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()

    var body: some View {
        List {
            Section("Account") {
                HStack { Text("Username"); Spacer(); Text(vm.username).foregroundColor(.secondary) }
                HStack { Text("Email"); Spacer(); Text(vm.email).foregroundColor(.secondary) }

                NavigationLink("Change Password") {
                    Form {
                        Section("Current Password") {
                            SecureField("Current password", text: $vm.currentPassword)
                        }
                        Section("New Password") {
                            SecureField("New password", text: $vm.newPassword)
                            SecureField("Confirm new password", text: $vm.confirmNewPassword)
                        }
                        Section { Button("Update Password") { vm.changePassword() } }
                        statusSection
                    }
                    .navigationTitle("Change Password")
                }

                Button(role: .destructive) { vm.signOut() } label: { Text("Sign Out") }
            }

            Section("Profile") {
                TextField("Full name", text: $vm.fullName)
                TextField("Bio", text: $vm.bio, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)

                Button("Save Profile") { vm.saveProfileBasics() }
            }

            Section("Preferences") {
                Toggle("Notifications", isOn: $vm.notificationsEnabled)
                Button("Save Preferences") { vm.savePreferences() }
            }

            statusSection
        }
        .navigationTitle("Settings")
        .onAppear { vm.onAppear() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { vm.reload() } label: { Image(systemName: "arrow.clockwise") }
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if vm.isLoading || vm.errorMessage != nil || vm.successMessage != nil {
            Section {
                if vm.isLoading { ProgressView("Working…") }
                if let e = vm.errorMessage { Text(e).foregroundColor(.red) }
                if let ok = vm.successMessage { Text(ok).foregroundColor(.green) }
            }
        }
    }
}
