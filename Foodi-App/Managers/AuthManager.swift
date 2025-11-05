import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthManager {
    static let shared = AuthManager()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Sign Up
    func signUp(fullName: String, username: String, bio: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let email = "\(username.lowercased())@foodiapp.com"

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = result?.user else { return }

            // User profile  data as before
            var userData: [String: Any] = [
                "uid": user.uid,
                "fullName": fullName,
                "username": username,
                "bio": bio,
                "createdAt": Timestamp(date: Date())
            ]

            userData["profilePicURL"] = ""
            userData["score"] = 0
            userData["metrics"] = [
                "postsCount": 0,
                "likesReceived": 0,
                "currentStreak": 0,
                "longestStreak": 0,
                "lastPostDate": ""            ]

            self.db.collection("users").document(user.uid).setData(userData, merge: true) { err in
                if let err = err {
                    completion(.failure(err))
                } else {
                    completion(.success(user))
                }
            }
        }
    }

    // MARK: - Sign In
    func signIn(username: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let email = "\(username.lowercased())@foodiapp.com"
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {

                self.ensureLeaderboardFields(for: user.uid)
                completion(.success(user))
            }
        }
    }

    // MARK: - Get Current User
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }

    // MARK: - Sign Out
    func signOut() -> Bool {
        do {
            try Auth.auth().signOut()
            return true
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Helpers
    /// Ensures the user doc has the leaderboard structure without overwriting real data.
    private func ensureLeaderboardFields(for uid: String) {
        let ref = db.collection("users").document(uid)
        ref.setData([
            "profilePicURL": FieldValue.delete(), // no-op if exists; we’ll merge default below
        ], merge: true)

        ref.setData([
            "profilePicURL": "",
            "score": 0,
            "metrics": [
                "postsCount": 0,
                "likesReceived": 0,
                "currentStreak": 0,
                "longestStreak": 0,
                "lastPostDate": ""
            ]
        ], merge: true)
    }
    // MARK: - Profile fetch/observe
    func loadUserProfile(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "No signed-in user"])))
            return
        }
        db.collection("users").document(uid).getDocument { snap, err in
            if let err = err { completion(.failure(err)); return }
            completion(.success(snap?.data() ?? [:]))
        }
    }

    func observeUserProfile(listener: @escaping ([String: Any]) -> Void) -> ListenerRegistration? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid).addSnapshotListener { snap, _ in
            listener(snap?.data() ?? [:])
        }
    }

    // MARK: - Preferences
    func setNotificationsEnabled(_ enabled: Bool, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "AuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "No signed-in user"]))
            return
        }
        db.collection("users").document(uid).setData(["notificationsEnabled": enabled], merge: true, completion: completion)
    }

    // MARK: - Basic profile updates
    func updateProfile(fullName: String? = nil, bio: String? = nil, profilePicURL: String? = nil, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "AuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "No signed-in user"]))
            return
        }
        var patch: [String: Any] = [:]
        if let fullName { patch["fullName"] = fullName }
        if let bio { patch["bio"] = bio }
        if let profilePicURL { patch["profilePicURL"] = profilePicURL }
        guard !patch.isEmpty else { completion(nil); return }
        db.collection("users").document(uid).setData(patch, merge: true, completion: completion)
    }

    // MARK: - Password (with reauth)
    func updatePassword(currentPassword: String, newPassword: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            completion(NSError(domain: "AuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "No signed-in user"]))
            return
        }
        let cred = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: cred) { _, reauthErr in
            if let reauthErr = reauthErr { completion(reauthErr); return }
            user.updatePassword(to: newPassword, completion: completion)
        }
    }

}
