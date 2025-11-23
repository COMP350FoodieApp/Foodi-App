//
//  PostRowView.swift
//  Foodi
//
//  Created by Francisco Campa on 11/23/25.
//

import SwiftUI

struct PostRowView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            if let url = post.imageURL, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 200)
                .cornerRadius(12)
            }

            HStack {
                Text(post.title)
                    .font(.headline)

                Spacer()

                if let restaurant = post.restaurant, !restaurant.isEmpty {
                    Text(restaurant)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let rating = post.rating {
                HStack(spacing: 4) {
                    ForEach(1..<6) { index in
                        Text("🍔")
                            .opacity(Double(index) <= rating ? 1 : 0.3)
                    }
                    Text(String(format: "%.1f", rating))
                        .foregroundColor(.secondary)
                }
            }

            Text(post.content)
                .font(.subheadline)
                .foregroundColor(.primary)

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
