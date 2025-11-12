//
//  SettingsViewModel.swift
//  Foodi
//
//  Created by d-rod on 11/5/25.
//


import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class SettingsViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var fullName: String = ""
    @Published var bio: String = ""
    @Published var notificationsEnabled: Bool = true

    // password inputs
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmNewPassword: String = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    func onAppear() {
        loadStaticAuthFields()
        startProfileListener()
    }

    func reload() {
        loadStaticAuthFields()
        isLoading = true
        AuthManager.shared.loadUserProfile { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let dict):
                self.apply(dict)
            case .failure(let err):
                self.errorMessage = err.localizedDescription
            }
        }
    }

    func savePreferences() {
        isLoading = true
        AuthManager.shared.setNotificationsEnabled(notificationsEnabled) { [weak self] err in
            guard let self = self else { return }
            self.isLoading = false
            if let err = err { self.errorMessage = err.localizedDescription }
            else { self.successMessage = "Preferences saved." }
        }
    }

    func saveProfileBasics() {
        isLoading = true
        AuthManager.shared.updateProfile(fullName: fullName, bio: bio, profilePicURL: nil) { [weak self] err in
            guard let self = self else { return }
            self.isLoading = false
            if let err = err { self.errorMessage = err.localizedDescription }
            else { self.successMessage = "Profile updated." }
        }
    }

    func changePassword() {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, newPassword == confirmNewPassword else {
            errorMessage = "Check your password fields."
            return
        }
        isLoading = true
        AuthManager.shared.updatePassword(currentPassword: currentPassword, newPassword: newPassword) { [weak self] err in
            guard let self = self else { return }
            self.isLoading = false
            if let err = err { self.errorMessage = err.localizedDescription }
            else {
                self.successMessage = "Password updated."
                self.currentPassword = ""; self.newPassword = ""; self.confirmNewPassword = ""
            }
        }
    }

    func signOut() {
        _ = AuthManager.shared.signOut()
    }

    // MARK: - Internals
    private func loadStaticAuthFields() {
        guard let user = AuthManager.shared.getCurrentUser() else { return }
        email = user.email ?? ""
        // Derive username from email pattern: username@foodiapp.com
        if let at = email.firstIndex(of: "@") {
            username = String(email[..<at])
        }
    }

    private func startProfileListener() {
        listener?.remove()
        listener = AuthManager.shared.observeUserProfile { [weak self] dict in
            self?.apply(dict)
        }
    }

    private func apply(_ dict: [String: Any]) {
        self.fullName = dict["fullName"] as? String ?? self.fullName
        self.bio = dict["bio"] as? String ?? self.bio
        if let n = dict["notificationsEnabled"] as? Bool {
            self.notificationsEnabled = n
        }
    }
}
