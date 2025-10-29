//
//  PostView.swift
//  Foodi
//
//  Created by Francisco Campa on 10/12/25.
//

import SwiftUI
import PhotosUI
import MapKit
import FirebaseStorage
import FirebaseAuth

struct PostView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var restaurantTag: String = ""
    @State private var selectedWidget: WidgetType? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showRestaurantMap = false
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    
    
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
                    
                    // Submit Button
                    Button(action: submitPost) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Post")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(title.isEmpty || description.isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(title.isEmpty || description.isEmpty || isSubmitting)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
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
        guard !title.isEmpty, !description.isEmpty else { return }
        isSubmitting = true
        errorMessage = ""
        
        if let imageData = selectedImageData {
            uploadImageAndSavePost(imageData: imageData)
        } else {
            savePostToFirestore(imageURL: nil)
        }
    }
    
    // MARK: - Upload to Firebase Storage
    private func uploadImageAndSavePost(imageData: Data) {
        let imageID = UUID().uuidString
        let storageRef = Storage.storage().reference().child("postImages/\(imageID).jpg")
        
        // Metadata helps Firebase recognize it as an image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Start upload
        let uploadTask = storageRef.putData(imageData, metadata: metadata)
        
        //Wait for upload to finish before fetching URL
        uploadTask.observe(.success) { _ in
            storageRef.downloadURL { url, error in
                if let error = error {
                    errorMessage = "Failed to get image URL: \(error.localizedDescription)"
                    isSubmitting = false
                    return
                }
                
                guard let imageURL = url?.absoluteString else {
                    errorMessage = "No download URL returned."
                    isSubmitting = false
                    return
                }
                
                print(" Uploaded image URL: \(imageURL)")
                savePostToFirestore(imageURL: imageURL)
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                errorMessage = "Upload failed: \(error.localizedDescription)"
            } else {
                errorMessage = "Upload failed: unknown reason."
            }
            isSubmitting = false
        }
    }
    
    
    
    
    // MARK: Save post to Firestore
    private func savePostToFirestore(imageURL: String?) {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "You must be logged in to post."
            isSubmitting = false
            return
        }
        
        PostManager.shared.addPost(
            title: title,
            content: description,
            imageURL: imageURL
        ) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    print(" Post saved for user \(user.uid)")
                    dismiss()
                case .failure(let error):
                    errorMessage = "Failed to save post: \(error.localizedDescription)"
                }
            }
        }
    }
}
