import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

// MARK: - Post Model
struct Post: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var imageURL: String?
    var author: String
    var authorId: String
    var restaurantName: String?
    var restaurant: String?
    var rating: Double?
    var timestamp: Date
}

// MARK: - Comment Model
struct Comment: Identifiable {
    let id: String
    let authorName: String
    let text: String
    let timestamp: Date
}

// MARK: - PostManager
class PostManager {
    static let shared = PostManager()
    private let db = Firestore.firestore()
    private init() {}
    
    // MARK: - Add Post
    func addPost(
        title: String,
        content: String,
        imageURL: String? = nil,
        restaurant: String? = nil,
        rating: Double? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            return completion(.failure(NSError(domain: "", code: 401,
                                               userInfo: [NSLocalizedDescriptionKey: "User not logged in."])))
        }

        let userRef = db.collection("users").document(user.uid)
        userRef.getDocument { snapshot, error in
            var displayName = "Unknown User"
            if let data = snapshot?.data(), let username = data["username"] as? String {
                displayName = username
            }

            // ✅ Final unified post data
            let postData: [String: Any] = [
                "title": title,
                "content": content,
                "imageURL": imageURL ?? "",
                "author": displayName,
                "authorId": user.uid,
                "restaurant": restaurant ?? "",
                "rating": rating ?? 0.0,
                "timestamp": Timestamp(date: Date())
            ]

            self.db.collection("posts").addDocument(data: postData) { error in
                if let error = error { completion(.failure(error)) }
                else { completion(.success(())) }
            }
        }
    }

    // MARK: - Fetch Posts
    func fetchPosts(completion: @escaping ([Post]) -> Void) {
        db.collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching posts: \(error?.localizedDescription ?? "Unknown")")
                    completion([])
                    return
                }
                
                let posts = documents.compactMap { doc -> Post? in
                    let data = doc.data()
                    return Post(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        content: data["content"] as? String ?? "",
                        imageURL: data["imageURL"] as? String,
                        author: data["author"] as? String ?? "",
                        authorId: data["authorId"] as? String ?? "",
                        restaurantName: data["restaurantName"] as? String ?? "",
                        restaurant: data["restaurant"] as? String ?? "",
                        rating: data["rating"] as? Double ?? 0.0,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                
                completion(posts)
            }
    }

    // MARK: - Delete Post
    func deletePost(_ post: Post, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            return completion(.failure(NSError(domain: "", code: 401,
                                               userInfo: [NSLocalizedDescriptionKey: "Not logged in."])))
        }
        
        // Convert current user email to username
        let currentUsername = user.email?.split(separator: "@").first.map(String.init) ?? ""
        
        let postAuthorUsername = post.author
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        let currentName = currentUsername
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        let ownsByUID = !post.authorId.isEmpty && post.authorId == user.uid
        let ownsByUsername = postAuthorUsername == currentName
        
        // Allow either UID match or username match
        guard ownsByUID || ownsByUsername else {
            return completion(.failure(NSError(domain: "", code: 403,
                                               userInfo: [NSLocalizedDescriptionKey: "You do not own this post."])))
        }
        
        // Delete image in Storage if exists
        if let imageURL = post.imageURL, !imageURL.isEmpty {
            let storageRef = Storage.storage().reference(forURL: imageURL)
            storageRef.delete { error in
                if let error = error {
                    print("⚠️ image delete warning:", error.localizedDescription)
                }
            }
        }
        
        // Delete Firestore document
        db.collection("posts").document(post.id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Likes
    func toggleLike(for post: Post, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not logged in"]))
        }

        let likeRef = db.collection("posts").document(post.id).collection("likes").document(uid)

        likeRef.getDocument { snapshot, error in
            if snapshot?.exists == true {
                // Unlike
                likeRef.delete(completion: completion)
            } else {
                // Like
                likeRef.setData(["timestamp": Timestamp(date: Date())], completion: completion)
            }
        }
    }

    func listenForLikes(of post: Post, completion: @escaping (Int) -> Void) {
        db.collection("posts").document(post.id).collection("likes")
            .addSnapshotListener { snap, _ in
                completion(snap?.documents.count ?? 0)
            }
    }

    // MARK: - Comments
    func addComment(to post: Post, text: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            return completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not logged in"]))
        }

        let comment: [String: Any] = [
            "authorId": user.uid,
            "authorName": user.email?.split(separator: "@").first.map(String.init) ?? "Unknown",
            "text": text,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("posts").document(post.id).collection("comments")
            .addDocument(data: comment, completion: completion)
    }

    func listenForComments(of post: Post, completion: @escaping ([Comment]) -> Void) {
        db.collection("posts").document(post.id).collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snap, _ in
                let comments = snap?.documents.compactMap { doc -> Comment? in
                    let data = doc.data()
                    return Comment(
                        id: doc.documentID,
                        authorName: data["authorName"] as? String ?? "Unknown",
                        text: data["text"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []
                completion(comments)
            }
    }
}
