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

            // Base profile data (unchanged)
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
                // ✅ ADDED: backfill leaderboard fields if an older account is missing them
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
}
