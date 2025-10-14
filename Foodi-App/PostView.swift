//
//  PostView.swift
//  Foodi
//
//  Created by Francisco Campa on 10/12/25.
//

import SwiftUI
import PhotosUI

struct PostView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
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
                    
                    // Title Field
                    TextField("Title", text: $title)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .font(.headline)
                    
                    // Description Field
                    TextField("Write a description...", text: $description, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    // File / Photo Picker
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Image(systemName: "paperclip.circle.fill")
                                .foregroundColor(.blue)
                            Text("Attach Photo or File")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .onChange(of: selectedPhoto) { newValue, _ in
                        Task {
                            if let item = newValue,
                               let data = try? await item.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }

                    
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
            .navigationTitle("New Post")
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
