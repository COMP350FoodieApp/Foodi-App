import SwiftUI

struct PostCardView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            if let imageURL = post.imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 220)
                .clipped()
            }

            Text(post.title)
                .font(.headline)

            if let restaurant = post.restaurantName, !restaurant.isEmpty {
                Label(restaurant, systemImage: "mappin.and.ellipse")
                    .foregroundColor(.foodiBlue)
            }

            Text(post.content)
                .font(.body)
                .lineLimit(3)

            Text("Posted by \(post.author)")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
        }
        .padding(.horizontal)
    }
}
