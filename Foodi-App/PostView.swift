//
//  PostView.swift
//  Foodi
//
//  Created by Francisco Campa on 10/12/25.
//

import SwiftUI
import PhotosUI
import MapKit

struct PostView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var restaurantTag: String = ""
    @State private var selectedWidget: WidgetType? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showRestaurantMap = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
    
                    // Image Picker Preview
                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipped()
                            .cornerRadius(16)
                            .shadow(radius: 3)
                    } else {
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.15))
                                .frame(height: 180)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 36))
                                            .foregroundColor(.blue)
                                        Text("Attach a photo")
                                            .foregroundColor(.blue)
                                            .font(.headline)
                                    }
                                )
                        }
                        .onChange(of: selectedPhoto) {
                            Task {
                                if let item = selectedPhoto,
                                   let data = try? await item.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                    }
                    
                    // Title Field
                    TextField("Title", text: $title)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .font(.headline)
                    
                    // Restaurant Tag Field
                    Button(action: {
                        showRestaurantMap = true
                    }) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.blue)
                            Text(restaurantTag.isEmpty ? "Select a restaurant" : restaurantTag)
                                .foregroundColor(restaurantTag.isEmpty ? .secondary : .primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .fullScreenCover(isPresented: $showRestaurantMap) {
                        MapWidgetView(onSelectRestaurant: { selectedRestaurant in
                            restaurantTag = selectedRestaurant.item.name ?? "Unknown"
                            showRestaurantMap = false
                        })
                    }
                    
                    // Description Field
                    TextField("Write a description...", text: $description, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    // (Removed file/photo picker with paperclip icon)

                    
                    // Submit Button
                    Button(action: submitPost) {
                        Text("Post")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(title.isEmpty || description.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(title.isEmpty || description.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Share Your Food")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Submit Action
    private func submitPost() {
        // Placeholder for posting logic (Firebase, backend, etc.)
        print("New post created:")
        print("Title: \(title)")
        print("Description: \(description)")
        if selectedImageData != nil {
            print("Image attached ")
        }
        
        dismiss()
    }
}
