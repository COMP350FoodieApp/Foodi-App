import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = true
    @State private var errorMessage = ""
    @State private var user: User? = Auth.auth().currentUser

    var body: some View {
        VStack(spacing: 24) {
            if let user = user {
                // MARK: - Logged In State
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(user.email ?? "Unknown")
                        .font(.headline)
                    
                    Button("Sign Out") {
                        AuthManager.shared.signOut()
                        self.user = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(.top, 50)
            } else {
                // MARK: - Login / Signup UI
                VStack(spacing: 16) {
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(.largeTitle).bold()
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    Button(isSignUp ? "Sign Up" : "Log In") {
                        handleAuth()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .padding(.top)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }

                    Button(isSignUp ? "Already have an account? Log in" : "Need an account? Sign up") {
                        isSignUp.toggle()
                    }
                    .font(.footnote)
                }
                .padding()
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            self.user = Auth.auth().currentUser
        }
    }

    // MARK: - Auth Logic
    private func handleAuth() {
        if isSignUp {
            AuthManager.shared.signUp(email: email, password: password) { result in
                switch result {
                case .success(let data):
                    user = data.user
                    errorMessage = ""
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            AuthManager.shared.signIn(email: email, password: password) { result in
                switch result {
                case .success(let data):
                    user = data.user
                    errorMessage = ""
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
