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
            
            // Save profile data
            let userData: [String: Any] = [
                "uid": user.uid,
                "fullName": fullName,
                "username": username,
                "bio": bio,
                "createdAt": Timestamp(date: Date())
            ]
            
            self.db.collection("users").document(user.uid).setData(userData) { err in
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
}
