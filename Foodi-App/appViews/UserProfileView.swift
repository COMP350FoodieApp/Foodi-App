import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    let userId: String   // 👈 The Firestore UID of the user to show

    @State private var username = ""
    @State private var bio = ""
    @State private var profileImageURL: String?
    @State private var followers = 0
    @State private var following = 0
    @State private var posts: [Post] = []
    @State private var isFollowing = false
    @State private var selectedPost: Post? = nil


    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Profile image
                if let profileImageURL,
                   let url = URL(string: profileImageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )
                }

                // MARK: - Username + Bio
                Text(username.isEmpty ? "User" : username)
                    .font(.title2)
                    .fontWeight(.semibold)

                if !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if Auth.auth().currentUser?.uid != userId {
                    Button(action: {
                        toggleFollow()
                    }) {
                        Text(isFollowing ? "Following" : "Follow")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFollowing ? Color.gray.opacity(0.3) : Color.blue)
                            .foregroundColor(isFollowing ? .black : .white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }

                // MARK: - Stats
                HStack(spacing: 40) {
                    VStack {
                        Text("\(posts.count)")
                            .font(.headline)
                        Text("Posts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack {
                        Text("\(followers)")
                            .font(.headline)
                        Text("Followers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack {
                        Text("\(following)")
                            .font(.headline)
                        Text("Following")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider().padding(.vertical, 8)

                // MARK: - Posts
                // MARK: - Posts
                LazyVStack(spacing: 16) {
                    ForEach(posts) { post in
                        NavigationLink {
                            PostDetailView(post: post)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                
                                // Image
                                if let imageURL = post.imageURL,
                                   let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(height: 200)
                                    .cornerRadius(10)
                                }

                                Text(post.title)
                                    .font(.headline)

                                Text(post.content)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                if Auth.auth().currentUser?.uid == userId {
                                    Button(role: .destructive) {
                                        PostManager.shared.deletePost(post) { result in
                                            switch result {
                                            case .success:
                                                loadPosts()
                                            case .failure(let error):
                                                print("Delete failed:", error.localizedDescription)
                                            }
                                        }
                                    } label: {
                                        Label("Delete Post", systemImage: "trash")
                                            .font(.subheadline)
                                            .padding(.top, 4)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }

            }
            .padding(.top)
        }
        .navigationTitle(username.isEmpty ? "Profile" : "@\(username)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadProfile()
            loadPosts()
            loadFollowerCounts()
            checkIfFollowing()
        }
    }

    // MARK: - Load Profile Info
    private func loadProfile() {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snap, _ in
            guard let data = snap?.data() else { return }
            self.username = data["username"] as? String ?? ""
            self.bio = data["bio"] as? String ?? ""
            // handle both possible field names
            self.profileImageURL = (data["profilePicURL"] as? String)
                ?? (data["profileImageURL"] as? String)
        }
    }

    // MARK: - Load Posts
    private func loadPosts() {
        let db = Firestore.firestore()
        db.collection("posts")
            .whereField("authorId", isEqualTo: self.userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snap, _ in
                guard let docs = snap?.documents else { return }
                self.posts = docs.map { doc in
                    let data = doc.data()
                    return Post(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        content: data["content"] as? String ?? "",
                        imageURL: data["imageURL"] as? String,
                        author: data["author"] as? String ?? "",
                        authorId: data["authorId"] as? String ?? "",
                        restaurant: data["restaurant"] as? String,
                        rating: data["rating"] as? Double ?? 0.0,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
            }
    }

    // MARK: - Load Follower Counts
    private func loadFollowerCounts() {
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("followers").getDocuments { snap, _ in
            self.followers = snap?.count ?? 0
        }
        db.collection("users").document(userId).collection("following").getDocuments { snap, _ in
            self.following = snap?.count ?? 0
        }
    }

    private func checkIfFollowing() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let followerDoc = db.collection("users").document(userId).collection("followers").document(currentUserId)
        followerDoc.getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                self.isFollowing = true
            } else {
                self.isFollowing = false
            }
        }
    }

    private func toggleFollow() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userFollowersRef = db.collection("users").document(userId).collection("followers").document(currentUserId)
        let currentUserFollowingRef = db.collection("users").document(currentUserId).collection("following").document(userId)

        if isFollowing {
            // Unfollow
            userFollowersRef.delete()
            currentUserFollowingRef.delete()
            isFollowing = false
            if followers > 0 {
                followers -= 1
            }
        } else {
            // Follow
            userFollowersRef.setData([:]) { error in
                if error == nil {
                    currentUserFollowingRef.setData([:]) { error in
                        if error == nil {
                            isFollowing = true
                            followers += 1
                            // === Notifications: Follow ===
                            if userId != currentUserId {
                                let notifRef = db.collection("users")
                                    .document(userId)
                                    .collection("notifications")

                                db.collection("users").document(currentUserId).getDocument { snap, _ in
                                    let fromUsername = (snap?.data()?["username"] as? String) ?? "Someone"

                                    let notifData: [String: Any] = [
                                        "type": "follow",
                                        "fromUserId": currentUserId,
                                        "fromUsername": fromUsername,
                                        "timestamp": Timestamp(date: Date())
                                    ]

                                    notifRef.addDocument(data: notifData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
