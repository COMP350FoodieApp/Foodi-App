import SwiftUI
import FirebaseFirestore

struct FeedView: View {
    @State private var posts: [Post] = []

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
                            Text("by \(post.author)")
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

    private func loadPosts() {
        PostManager.shared.fetchPosts { fetchedPosts in
            DispatchQueue.main.async {
                posts = fetchedPosts
            }
        }
    }
}
