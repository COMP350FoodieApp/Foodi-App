import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PublicProfileView: View {
    let userId: String

    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var profilePicURL: String = ""
    @State private var posts: [Post] = []
    @State private var selectedPost: Post? = nil


    @State private var followersCount = 0
    @State private var followingCount = 0
    @State private var isFollowing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Photo
                AsyncImage(url: URL(string: profilePicURL)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.25)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                
                // Username
                Text(username.isEmpty ? "User" : username)
                    .font(.title2).bold()
                
                // Bio
                if !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Followers / Following counts
                HStack(spacing: 32) {
                    VStack { Text("\(followersCount)").font(.headline); Text("Followers").font(.caption) }
                    VStack { Text("\(followingCount)").font(.headline); Text("Following").font(.caption) }
                }
                
                // Follow button (hide if viewing self)
                if let me = Auth.auth().currentUser?.uid, me != userId {
                    Button(action: toggleFollow) {
                        Text(isFollowing ? "Following" : "Follow")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(isFollowing ? Color.gray.opacity(0.2) : Color.foodiBlue)
                            .foregroundColor(isFollowing ? .primary : .white)
                            .cornerRadius(10)
                    }
                }
                
                Divider().padding(.vertical, 8)
                
                // User's posts (Grid layout)
                let columns = [
                    GridItem(.flexible(), spacing: 4),
                    GridItem(.flexible(), spacing: 4),
                    GridItem(.flexible(), spacing: 4)
                ]
                
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(posts) { post in
                        ZStack {
                            if let url = post.imageURL, let imgURL = URL(string: url) {
                                AsyncImage(url: imgURL) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                            } else {
                                Color.gray.opacity(0.3)
                            }
                        }
                        .frame(height: 120)
                        .clipped()
                        .onTapGesture {
                            selectedPost = post
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadAll)
        .fullScreenCover(item: $selectedPost) { post in
            NavigationStack {
                PostDetailView(post: post)
            }
        }

    }

    private func loadAll() {
        loadHeader()
        listenCountsAndFollowingState()
        PostManager.shared.fetchPostsByUser(userId: userId) { posts in
            self.posts = posts
        }
    }

    private func loadHeader() {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snap, _ in
            guard let data = snap?.data() else { return }
            self.username = (data["username"] as? String) ?? ""
            self.bio = (data["bio"] as? String) ?? ""
            self.profilePicURL = (data["profilePicURL"] as? String) ?? ""
        }
    }

    private func listenCountsAndFollowingState() {
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("followers")
            .addSnapshotListener { snap, _ in
                self.followersCount = snap?.count ?? 0
            }
        
        if let me = Auth.auth().currentUser?.uid {
            db.collection("users").document(me).collection("following")
                .document(userId)
                .addSnapshotListener { doc, _ in
                    self.isFollowing = doc?.exists ?? false
                }
        }
    }
    
    private func toggleFollow() {
        guard let me = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let myFollowing = db.collection("users").document(me).collection("following").document(userId)
        let theirFollowers = db.collection("users").document(userId).collection("followers").document(me)

        if isFollowing {
            myFollowing.delete()
            theirFollowers.delete()
        } else {
            let payload = ["timestamp": Timestamp()] as [String: Any]
            myFollowing.setData(payload, merge: true)
            theirFollowers.setData(payload, merge: true)
        }

    }
}

