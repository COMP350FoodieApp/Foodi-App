import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PostDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    let post: Post
    @State private var commentText = ""
    @State private var likeCount: Int = 0
    @State private var userHasLiked = false
    @State private var comments: [Comment] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Image
                if let imageURL = post.imageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipped()
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(post.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let restaurant = post.restaurantName, !restaurant.isEmpty {
                        Label(restaurant, systemImage: "mappin.and.ellipse")
                            .foregroundColor(.foodiBlue)
                    }
                }
                
                Text(post.content)
                    .font(.body)
                
                Text("Posted by \(post.author)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider().padding(.vertical, 8)
                
                // LIKE BUTTON
                Button {
                    PostManager.shared.toggleLike(for: post) { _ in }
                } label: {
                    Label("\(likeCount) Like\(likeCount == 1 ? "" : "s")", systemImage: userHasLiked ? "heart.fill" : "heart")
                        .foregroundColor(userHasLiked ? .red : .primary)
                        .font(.headline)
                }
                
                Divider().padding(.vertical, 8)
                
                // COMMENTS
                Text("Comments")
                    .font(.headline)
                
                if comments.isEmpty {
                    Text("No comments yet. Be the first!")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(comments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(comment.authorName)
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text(comment.text)
                                .font(.body)
                        }
                        .padding(.vertical, 6)
                        
                        Divider()
                    }
                }
                
                // COMMENT INPUT
                HStack {
                    TextField("Add a comment...", text: $commentText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Send") {
                        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        
                        PostManager.shared.addComment(to: post, text: trimmed) { error in
                            if let error = error {
                                print("COMMENT WRITE ERROR:", error.localizedDescription)
                            } else {
                                print("COMMENT SAVED")

                                DispatchQueue.main.async {
                                    commentText = ""
                                    hideKeyboard()
                                }
                            }
                        }
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                }
                .padding(.top, 6)
                
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .bold()
                }
            }
        }
        .onAppear {
            PostManager.shared.listenForLikes(of: post) { count in
                likeCount = count
            }
            
            if let uid = Auth.auth().currentUser?.uid {
                Firestore.firestore().collection("posts").document(post.id)
                    .collection("likes").document(uid)
                    .addSnapshotListener { snapshot, _ in
                        userHasLiked = snapshot?.exists ?? false
                    }
            }
            
            PostManager.shared.listenForComments(of: post) { newComments in
                comments = newComments
            }
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
