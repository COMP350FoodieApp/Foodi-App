import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SavedPostsView: View {
    @State private var savedPosts: [Post] = []
    
    var body: some View {
        NavigationView {
            Group {
                if savedPosts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("No saved posts yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Bookmark posts to view them here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(savedPosts) { post in
                        NavigationLink(destination: PostDetailView(post: post)) {
                            HStack(spacing: 12) {

                                // Thumbnail Image
                                if let urlString = post.imageURL,
                                   let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.3)
                                    }
                                    .frame(width: 70, height: 70)
                                    .clipped()
                                    .cornerRadius(8)
                                } else {
                                    // Placeholder if no image
                                    ZStack {
                                        Color.gray.opacity(0.3)
                                        Image(systemName: "photo")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(8)
                                }

                                // Text Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(post.title)
                                        .font(.headline)
                                        .lineLimit(1)

                                    Text(post.content)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                    
                                    if let restaurant = post.restaurant, !restaurant.isEmpty {
                                        Text("📍 \(restaurant)")
                                            .font(.caption)
                                            .foregroundColor(.foodiBlue)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                // Unsave logic
                                if let uid = Auth.auth().currentUser?.uid {
                                    let db = Firestore.firestore()
                                    db.collection("users")
                                        .document(uid)
                                        .collection("savedPosts")
                                        .document(post.id)
                                        .delete()
                                }
                            } label: {
                                Label("Unsave", systemImage: "bookmark.slash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved Posts")
            .onAppear(perform: loadSavedPosts)
        }
    }
    
    private func loadSavedPosts() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()

        db.collection("users")
            .document(uid)
            .collection("savedPosts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else {
                    self.savedPosts = []
                    return
                }

                var updated: [Post] = []

                for doc in docs {
                    let postId = doc.documentID

                    db.collection("posts").document(postId).getDocument { postSnap, _ in
                        if let data = postSnap?.data() {
                            let post = Post(
                                id: postId,
                                title: data["title"] as? String ?? "",
                                content: data["content"] as? String ?? "",
                                imageURL: data["imageURL"] as? String,
                                author: data["author"] as? String ?? "",
                                authorId: data["authorId"] as? String ?? "",
                                restaurant: data["restaurant"] as? String,
                                rating: data["rating"] as? Double ?? 0.0,
                                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            )

                            updated.append(post)

                            DispatchQueue.main.async {
                                self.savedPosts = updated
                            }
                        }
                    }
                }
            }
    }
}
