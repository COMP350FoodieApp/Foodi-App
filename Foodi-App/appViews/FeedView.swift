import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FeedContainer: View {
    @State private var posts: [Post] = []
    @State private var usernames: [String: String] = [:]
    @State private var selectedPost: Post? = nil
    
    
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
                            
                            if let currentUser = Auth.auth().currentUser {
                                let email = currentUser.email ?? ""
                                let currentUsername = email.split(separator: "@").first.map(String.init) ?? ""

                                let ownsByUID = !post.authorId.isEmpty && post.authorId == currentUser.uid
                                let ownsByName = post.author.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                                    == currentUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                                if ownsByUID || ownsByName {
                                    Button(role: .destructive) {
                                        PostManager.shared.deletePost(post) { result in
                                            switch result {
                                            case .success: loadPosts()
                                            case .failure(let error): print("Delete failed:", error.localizedDescription)
                                            }
                                        }
                                    } label: {
                                        Label("Delete Post", systemImage: "trash")
                                    }
                                    .padding(.top, 4)
                                }
                            }

                            
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .onTapGesture { selectedPost = post }
                    }
                }
            }
            .navigationTitle("Food Feed")
            .onAppear(perform: loadPosts)
            .fullScreenCover(item: $selectedPost) { post in
                NavigationStack {
                    PostDetailView(post: post)
                }
            }

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
