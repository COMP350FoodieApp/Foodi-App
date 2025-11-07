import SwiftUI
import FirebaseAuth
import FirebaseFirestore

import FirebaseStorage

struct ProfileView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Auth state
    @State private var currentUser: User? = AuthManager.shared.getCurrentUser()
    @State private var isSignUp = false
    
    // MARK: - Form state
    @State private var username = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    
    // MARK: - Profile data state
    @State private var profileImageURL: URL?
    @State private var fullName: String = ""
    @State private var bio: String = ""
    @State private var followersCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var postsCount: Int = 0
    @State private var posts: [Post] = []
    @State private var isLoadingProfile = false

    // MARK: - Edit Profile State
    @State private var showEditSheet: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var newBio: String = ""
    @State private var newFullName: String = ""
    @State private var isUpdatingProfile: Bool = false
    @State private var showImagePicker: Bool = false
    
    private let db = Firestore.firestore()
    
    private var formIsValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 8
    }
    
    var body: some View {
        NavigationView {
            Group {
                if currentUser == nil {
                    // MARK: - Login / Signup Form
                    VStack(spacing: 20) {
                        Text(isSignUp ? "Sign Up" : "Log In")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        TextField("Username", text: $username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        
                        SecureField("Password (min 8 characters)", text: $password)
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                        
                        Button {
                            handleAuthAction()
                        } label: {
                            HStack {
                                if isSubmitting { ProgressView().tint(.white) }
                                Text(isSignUp ? "Create Account" : "Log In")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!formIsValid || isSubmitting)
                        
                        Button(isSignUp ? "Already have an account? Log in" : "Need an account? Sign up") {
                            withAnimation {
                                isSignUp.toggle()
                                errorMessage = ""
                            }
                        }
                        .font(.footnote)
                        .padding(.top, 4)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    // MARK: - Logged In Profile View
                    ScrollView {
                        VStack(spacing: 16) {
                            if isLoadingProfile {
                                ProgressView()
                                    .padding(.top, 40)
                            } else {
                                VStack(spacing: 12) {
                                    if let url = profileImageURL {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(width: 100, height: 100)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(Circle())
                                            case .failure:
                                                Image(systemName: "person.crop.circle.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 100, height: 100)
                                                    .foregroundColor(.secondary)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.secondary)
                                    }

                                    Text(fullName.isEmpty ? username : fullName)
                                        .font(.title)
                                        .fontWeight(.bold)

                                    if !bio.isEmpty {
                                        Text(bio)
                                            .font(.body)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }

                                    // MARK: - Edit Profile Button (only for current user's own profile)
                                    if let loggedInUser = Auth.auth().currentUser,
                                       loggedInUser.uid == currentUser?.uid {
                                        Button(action: {
                                            newFullName = fullName
                                            newBio = bio
                                            selectedImage = nil
                                            showEditSheet = true
                                        }) {
                                            Text("Edit Profile")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .padding(.horizontal, 24)
                                                .padding(.vertical, 8)
                                                .background(Color.accentColor.opacity(0.15))
                                                .foregroundColor(.accentColor)
                                                .cornerRadius(20)
                                        }
                                        .padding(.top, 4)
                                    }

                                    HStack(spacing: 40) {
                                        VStack {
                                            Text("\(postsCount)")
                                                .font(.headline)
                                            Text("Posts")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        VStack {
                                            Text("\(followersCount)")
                                                .font(.headline)
                                            Text("Followers")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        VStack {
                                            Text("\(followingCount)")
                                                .font(.headline)
                                            Text("Following")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                                .padding(.top, 20)

                                Divider()
                                    .padding(.vertical, 10)

                                if posts.isEmpty {
                                    Text("No posts yet.")
                                        .foregroundColor(.secondary)
                                        .padding()
                                } else {
                                    LazyVStack(spacing: 16) {
                                        ForEach(posts) { post in
                                            VStack(alignment: .leading, spacing: 8) {
                                                if let imageURL = post.imageURL, let url = URL(string: imageURL) {
                                                    AsyncImage(url: url) { image in
                                                        image.resizable()
                                                            .scaledToFill()
                                                    } placeholder: {
                                                        ProgressView()
                                                    }
                                                    .frame(height: 180)
                                                    .cornerRadius(10)
                                                }

                                                Text(post.title)
                                                    .font(.headline)
                                                Text(post.content)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)

                                                if let rating = post.rating {
                                                    HStack(spacing: 4) {
                                                        ForEach(1..<6) { i in
                                                            Text("🍔")
                                                                .font(.system(size: 16))
                                                                .opacity(Double(i) <= rating ? 1.0 : 0.3)
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .navigationTitle("Profile")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Log Out") {
                                handleSignOut()
                            }
                        }
                    }
                    .onAppear {
                        loadUserProfile()
                    }
                    // MARK: - Edit Profile Sheet
                    .sheet(isPresented: $showEditSheet) {
                        EditProfileSheet
                    }
                }
            }
        }
    }
    
    // MARK: - Auth Flow
    private func handleAuthAction() {
        errorMessage = ""
        guard !username.isEmpty, password.count >= 8 else {
            errorMessage = "Please enter a valid username and password (min 8 characters)."
            return
        }
        isSubmitting = true
        
        if isSignUp {
            AuthManager.shared.signUp(fullName: "", username: username, bio: "", password: password) { result in
                DispatchQueue.main.async {
                    isSubmitting = false
                    switch result {
                    case .success(let user):
                        currentUser = user
                        loadUserProfile()
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            AuthManager.shared.signIn(username: username, password: password) { result in
                DispatchQueue.main.async {
                    isSubmitting = false
                    switch result {
                    case .success(let user):
                        currentUser = user
                        loadUserProfile()
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func handleSignOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            username = ""
            password = ""
            fullName = ""
            bio = ""
            followersCount = 0
            followingCount = 0
            postsCount = 0
            posts = []
            profileImageURL = nil
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Load Profile Data
    private func loadUserProfile() {
        guard let uid = currentUser?.uid else { return }
        isLoadingProfile = true
        
        let userDocRef = db.collection("users").document(uid)
        userDocRef.getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    isLoadingProfile = false
                    errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    return
                }
                guard let data = snapshot?.data() else {
                    isLoadingProfile = false
                    errorMessage = "User data not found."
                    return
                }
                
                // Use correct Firestore field keys
                fullName = data["fullName"] as? String ?? ""
                bio = data["bio"] as? String ?? ""
                username = data["username"] as? String ?? username // fallback to previous username
                postsCount = data["postsCount"] as? Int ?? 0
                if let profileImageString = data["profilePicURL"] as? String, let url = URL(string: profileImageString) {
                    profileImageURL = url
                } else {
                    profileImageURL = nil
                }
                
                // Fetch followers count from subcollection
                let followersRef = db.collection("users").document(uid).collection("followers")
                followersRef.getDocuments { followersSnapshot, _ in
                    followersCount = followersSnapshot?.documents.count ?? 0
                    
                    // Fetch following count from subcollection
                    let followingRef = db.collection("users").document(uid).collection("following")
                    followingRef.getDocuments { followingSnapshot, _ in
                        followingCount = followingSnapshot?.documents.count ?? 0
                        isLoadingProfile = false
                        // Now load posts
                        loadUserPosts(uid: uid)
                    }
                }
            }
        }
    }
    
    private func loadUserPosts(uid: String) {
        db.collection("posts")
            .whereField("authorId", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Failed to load posts: \(error.localizedDescription)"
                        self.posts = []
                        return
                    }
                    
                    let fetchedPosts = snapshot?.documents.compactMap { doc -> Post? in
                        let data = doc.data()
                        return Post(
                            id: doc.documentID,
                            title: data["title"] as? String ?? "",
                            content: data["content"] as? String ?? "",
                            imageURL: data["imageURL"] as? String,
                            author: data["author"] as? String ?? "",
                            authorId: data["authorId"] as? String ?? "",
                            restaurant: data["restaurant"] as? String,
                            rating: data["rating"] as? Double ?? 0.0,
                            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    } ?? []
                    
                    // 🟡 Fallback: if no posts found by UID, try fetching by author name
                    if fetchedPosts.isEmpty {
                        self.db.collection("posts")
                            .whereField("author", isEqualTo: self.username)
                            .order(by: "timestamp", descending: true)
                            .getDocuments { snap, err in
                                DispatchQueue.main.async {
                                    if let err = err {
                                        self.errorMessage = "Failed to load posts by username: \(err.localizedDescription)"
                                        self.posts = []
                                    } else {
                                        self.posts = snap?.documents.compactMap { doc -> Post? in
                                            let data = doc.data()
                                            return Post(
                                                id: doc.documentID,
                                                title: data["title"] as? String ?? "",
                                                content: data["content"] as? String ?? "",
                                                imageURL: data["imageURL"] as? String,
                                                author: data["author"] as? String ?? "",
                                                authorId: data["authorId"] as? String ?? "",
                                                restaurant: data["restaurant"] as? String,
                                                rating: data["rating"] as? Double ?? 0.0,
                                                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                                            )
                                        } ?? []
                                        self.postsCount = self.posts.count
                                    }
                                }
                            }
                    } else {
                        self.posts = fetchedPosts
                        self.postsCount = fetchedPosts.count

                    }
                }
            }
    }
    
    // MARK: - Edit Profile Sheet
    private var EditProfileSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Image Picker
                ZStack {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else if let url = profileImageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.secondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.secondary)
                    }
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 2)
                        .frame(width: 100, height: 100)
                }
                .onTapGesture {
                    showImagePicker = true
                }
                .padding(.top, 24)

                // Full Name
                TextField("Full Name", text: $newFullName)
                    .textContentType(.name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                // Bio
                VStack(alignment: .leading) {
                    Text("Bio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $newBio)
                        .frame(height: 80)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                // Save Changes Button
                Button(action: {
                    updateProfile()
                }) {
                    HStack {
                        if isUpdatingProfile { ProgressView().tint(.white) }
                        Text("Save Changes")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isUpdatingProfile)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showEditSheet = false
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }

    // MARK: - Update Profile Function
    private func updateProfile() {
        guard let uid = currentUser?.uid else { return }
        isUpdatingProfile = true
        var fieldsToUpdate: [String: Any] = [
            "fullName": newFullName,
            "bio": newBio
        ]

        func finishUpdate(with imageURL: String?) {
            if let imageURL = imageURL {
                fieldsToUpdate["profilePicURL"] = imageURL
            }
            db.collection("users").document(uid).updateData(fieldsToUpdate) { error in
                DispatchQueue.main.async {
                    isUpdatingProfile = false
                    if let error = error {
                        errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    } else {
                        fullName = newFullName
                        bio = newBio
                        if let imageURL = imageURL {
                            profileImageURL = URL(string: imageURL)
                        }
                        showEditSheet = false
                    }
                }
            }
        }

        // If a new image is selected, upload to Firebase Storage
        if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    DispatchQueue.main.async {
                        isUpdatingProfile = false
                        errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    }
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            isUpdatingProfile = false
                            errorMessage = "Failed to get image URL: \(error.localizedDescription)"
                        }
                        return
                    }
                    finishUpdate(with: url?.absoluteString)
                }
            }
        } else {
            finishUpdate(with: nil)
        }
    }
}


// MARK: - UIKit Image Picker Wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
