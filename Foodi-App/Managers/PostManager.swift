import Foundation
import FirebaseFirestore
import FirebaseAuth

struct Post: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var content: String
    var imageURL: String?
    var author: String
    var timestamp: Date = Date()
}

class PostManager {
    static let shared = PostManager()
    private let db = Firestore.firestore()
    private init() {}

    //Save a post
    func addPost(title: String, content: String, imageURL: String? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])))
            return
        }

        let postData: [String: Any] = [
            "title": title,
            "content": content,
            "imageURL": imageURL ?? "",
            "author": user.uid,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("posts").addDocument(data: postData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    //Fetch posts
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
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                completion(posts)
            }
    }
}

