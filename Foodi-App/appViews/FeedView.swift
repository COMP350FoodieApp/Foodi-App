import SwiftUI
import FirebaseFirestore
import FirebaseAuth


enum FeedType: String, CaseIterable {
    case explore = "Explore"
    case forYou = "For You"
    case following = "Following"
}

struct FeedContainer: View {
    @State private var posts: [Post] = []
    @State private var usernames: [String: String] = [:]
    @State private var selectedPost: Post? = nil
    @State private var feedType: FeedType = .explore
    @State private var savedStates: [String: Bool] = [:]
    
    var body: some View {
        NavigationStack {
            VStack {
                
                Picker("Feed", selection: $feedType) {
                    ForEach(FeedType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .onChange(of: feedType) {
                    loadPosts()
                }

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            VStack(alignment: .leading, spacing: 10) {
                                
                                // 🖼️ Post image
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
                                
                                // 🏷️ Title + restaurant
                                HStack {
                                    Text(post.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if let restaurant = post.restaurant, !restaurant.isEmpty {
                                        Text(restaurant)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // 🍔 Rating row
                                if let rating = post.rating {
                                    HStack(spacing: 4) {
                                        ForEach(1..<6) { burger in
                                            Text("🍔")
                                                .font(.system(size: 20))
                                                .opacity(Double(burger) <= rating ? 1.0 : 0.25)
                                        }
                                        Text(String(format: "%.1f", rating))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // 📝 Content
                                Text(post.content)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                // 👤 Author
                                Text("by \(usernames[post.authorId] ?? post.author)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Spacer()
                                    Button {
                                        PostManager.shared.toggleSaved(postId: post.id) { saved in
                                            savedStates[post.id] = saved
                                        }
                                    } label: {
                                        Image(systemName: (savedStates[post.id] ?? false) ? "bookmark.fill" : "bookmark")
                                            .font(.title2)
                                            .foregroundColor((savedStates[post.id] ?? false) ? .blue : .secondary)
                                    }
                                }
                                
                                // 🗑️ Delete button (owner only)
                                if let currentUser = Auth.auth().currentUser {
                                    let email = currentUser.email ?? ""
                                    let currentUsername = email.split(separator: "@").first.map(String.init) ?? ""
                                    
                                    let ownsByUID = !post.authorId.isEmpty && post.authorId == currentUser.uid
                                    let ownsByName = post.author
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                        .lowercased() ==
                                    currentUsername
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                        .lowercased()
                                    
                                    if ownsByUID || ownsByName {
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
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .onTapGesture { selectedPost = post }
                            .onAppear {
                                PostManager.shared.isPostSaved(postId: post.id) { saved in
                                    savedStates[post.id] = saved
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Food Feed")
            .onAppear {
                if let _ = Auth.auth().currentUser?.uid {
                    loadPosts()
                } else {
                    print("Waiting for Firebase Auth to finish...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        loadPosts()
                    }
                }
            }

            .fullScreenCover(item: $selectedPost) { post in
                NavigationStack {
                    PostDetailView(post: post)
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func fetchUsernames(for posts: [Post]) {
        let userIds = Set(posts.map { $0.authorId }).filter { !$0.isEmpty }

        for uid in userIds where usernames[uid] == nil {
            Firestore.firestore().collection("users").document(uid).getDocument { snapshot, _ in
                if let data = snapshot?.data(),
                   let username = data["username"] as? String {
                    usernames[uid] = username
                } else {
                    usernames[uid] = uid
                }
            }
        }
    }

    
    
    private func loadPosts() {
        switch feedType {
            
        case .explore:
            PostManager.shared.fetchPosts { fetched in
                DispatchQueue.main.async {
                    posts = fetched
                    fetchUsernames(for: fetched)
                }
            }
            
        case .following:
            guard let uid = Auth.auth().currentUser?.uid else { return }
            PostManager.shared.fetchFollowingPosts(for: uid) { fetched in
                DispatchQueue.main.async {
                    posts = fetched
                    fetchUsernames(for: fetched)
                }
            }
            
        case .forYou:
            guard let uid = Auth.auth().currentUser?.uid else { return }
            PostManager.shared.fetchForYouPosts(for: uid) { fetched in
                DispatchQueue.main.async {
                    posts = fetched
                    fetchUsernames(for: fetched)
                }
            }
        }
    }
}
