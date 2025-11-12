import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Search Model (avoid conflict with FirebaseAuth.User)
struct SearchUser: Identifiable, Hashable {
    let id: String                // Firestore documentID
    let username: String
    let profileImageURL: String?
    let bio: String?// optional
}

// MARK: - Search View
struct UserSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var users: [SearchUser] = []
    @State private var selectedUser: SearchUser? = nil

    var body: some View {
        ZStack {
            VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                .ignoresSafeArea()

            VStack {
                if users.isEmpty && query.isEmpty == false {
                    Text("No users found")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else {
                    List(users) { user in
                        NavigationLink(destination: UserProfileView(userId: user.id)) {
                            HStack {
                                AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())

                                Text(user.username)
                                    .font(.headline)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Search Users")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search users...")
            .onChange(of: query) {
                performSearch()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func performSearch() {
        guard !query.isEmpty else {
            users = []
            return
        }

        let db = Firestore.firestore()
        print("Searching for users matching: \(query)")

        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Firestore error: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot else {
                print("❌ No snapshot returned")
                return
            }

            // Map Firestore -> SearchUser
            let allUsers: [SearchUser] = snapshot.documents.compactMap { doc -> SearchUser? in
                let data = doc.data()
                guard let username = data["username"] as? String else { return nil }
                let bio = data["bio"] as? String;                let profileURL = doc["profileImageURL"] as? String
                return SearchUser(
                    id: doc.documentID,
                    username: username,
                    profileImageURL: profileURL,
                    bio: bio
                )
            }

            // Local filter (case-insensitive contains)
            self.users = allUsers.filter {
                $0.username.localizedCaseInsensitiveContains(query)
            }
        }
    }
}

// MARK: - User Profile Sheet (safe name)
struct UserProfileSheet: View {
    let user: SearchUser
    @State private var isFollowing = false

    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())

            Text(user.username)
                .font(.title)
                .bold()

            if Auth.auth().currentUser != nil {
                Button(action: toggleFollow) {
                    Text(isFollowing ? "Following" : "Follow")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(isFollowing ? Color.gray.opacity(0.2) : Color.foodiBlue)
                        .foregroundColor(isFollowing ? .black : .white)
                        .cornerRadius(8)
                }
            }

            Spacer()
        }
        .padding()
        .onAppear(perform: checkIfFollowing)
    }

    private func checkIfFollowing() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(currentUserID)
            .collection("following")
            .document(user.id)
            .getDocument { doc, _ in
                isFollowing = doc?.exists ?? false
            }
    }

    private func toggleFollow() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let followingRef = db.collection("users").document(currentUserID)
            .collection("following").document(user.id)
        let followerRef = db.collection("users").document(user.id)
            .collection("followers").document(currentUserID)

        if isFollowing {
            followingRef.delete()
            followerRef.delete()
            isFollowing = false
        } else {
            let payload = ["timestamp": Timestamp()]
            followingRef.setData(payload)
            followerRef.setData(payload)
            isFollowing = true
        }
    }
}

// MARK: - Blur Helper
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
