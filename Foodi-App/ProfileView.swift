import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    // Form state
    @State private var fullName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var bio = ""
    @State private var showPassword = false
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    
    // Auth state
    @State private var currentUser: User? = AuthManager.shared.getCurrentUser()
    @State private var isSignUp = true
    
    private var formIsValid: Bool {
        if isSignUp {
            return !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !username.trimmingCharacters(in: .whitespaces).isEmpty &&
                   password.count >= 8
        } else {
            return !username.trimmingCharacters(in: .whitespaces).isEmpty &&
                   password.count >= 8
        }
    }
 
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                
                if let user = currentUser {
                    // MARK: - Logged-in view
                    VStack(spacing: 10) {
                        Text("Welcome back,")
                            .font(.headline)
                        Text(user.email ?? "Unknown user")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Button("Sign Out") {
                            if AuthManager.shared.signOut() {
                                currentUser = nil
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .padding(.top, 8)
                    }
                } else {
                    // MARK: - Signup/Login form
                    if isSignUp {
                        TextField("Full name", text: $fullName)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    ZStack {
                        Group {
                            if showPassword {
                                TextField("Password (min 8 characters)", text: $password)
                            } else {
                                SecureField("Password (min 8 characters)", text: $password)
                            }
                        }
                        .textContentType(.newPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        
                        HStack {
                            Spacer()
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .imageScale(.medium)
                                    .padding(.trailing, 12)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    if isSignUp {
                        TextField("Short bio (optional)", text: $bio)
                            .textInputAutocapitalization(.sentences)
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        handleAuthAction()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            }
                            Text(isSignUp ? "Create Profile" : "Log In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!formIsValid || isSubmitting)
                    .padding(.top, 8)
                    
                    Button(isSignUp ? "Already have an account? Log in" : "Need an account? Sign up") {
                        withAnimation {
                            isSignUp.toggle()
                        }
                    }
                    .font(.footnote)
                    .padding(.top, 4)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Profile")
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        }
    }
    
    // MARK: - Auth Flow
    private func handleAuthAction() {
        guard !username.isEmpty, password.count >= 8 else { return }
        isSubmitting = true
        errorMessage = ""
        
        if isSignUp {
            AuthManager.shared.signUp(fullName: fullName, username: username, bio: bio, password: password) { result in
                DispatchQueue.main.async {
                    isSubmitting = false
                    switch result {
                    case .success(let user):
                        currentUser = user
                        showSuccess = true
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
                        showSuccess = true
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}
