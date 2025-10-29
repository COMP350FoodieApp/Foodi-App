import SwiftUI
import FirebaseFirestore

struct FeedView: View {
    @State private var posts: [Post] = []
    @State private var usernames: [String: String] = [:]
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(posts) { post in
                        VStack(alignment: .leading, spacing: 8) {
                            //Load image from Firebase Storage URL
                            if let imageURL = post.imageURL, !imageURL.isEmpty {
                                AsyncImage(url: URL(string: imageURL)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(height: 200)
                                .cornerRadius(12)
                            }
                            
                            // Text fields
                            Text(post.title)
                                .font(.headline)
                            Text(post.content)
                                .font(.subheadline)
                            Text("by \(usernames[post.author] ?? post.author)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Food Feed")
            .onAppear(perform: loadPosts)
        }
    }
    
    private func fetchUsernames(for posts: [Post]) {
        let userIds = Set(posts.map { $0.author })
        for uid in userIds where usernames[uid] == nil {
            Firestore.firestore().collection("users").document(uid).getDocument { snapshot, _ in
                if let data = snapshot?.data(), let username = data["username"] as? String {
                    usernames[uid] = username
                } else {
                    usernames[uid] = uid
                }
            }

        }
    }
    
    
    private func loadPosts() {
        PostManager.shared.fetchPosts { fetchedPosts in
            DispatchQueue.main.async {
                posts = fetchedPosts
                fetchUsernames(for: fetchedPosts)
            }
        }
    }
}
