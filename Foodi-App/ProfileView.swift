import SwiftUI

struct ProfileView: View {
    // form state
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var bio: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showSuccess: Bool = false

    // lightweight validation
    private var formIsValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 8
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // avatar
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)

                // full name
                TextField("Full name", text: $fullName)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                // username
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                // password (with show/hide)
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
                        .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                // optional bio
                TextField("Short bio (optional)", text: $bio)
                    .textInputAutocapitalization(.sentences)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                // create profile button
                Button {
                    createProfile()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        }
                        Text("Create Profile")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!formIsValid || isSubmitting)
                .padding(.top, 8)

                // tiny helper text
                VStack(spacing: 4) {
                    if fullName.isEmpty { Text("• Enter your full name").foregroundStyle(.secondary).font(.footnote) }
                    if username.isEmpty { Text("• Choose a username").foregroundStyle(.secondary).font(.footnote) }
                    if password.count < 8 { Text("• Password must be at least 8 characters").foregroundStyle(.secondary).font(.footnote) }
                }
                .padding(.top, -6)
            }
            .padding()
        }
        .navigationTitle("Profile")
        .alert("Profile created!", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        }
    }

    // stub action you can wire to your backend later
    private func createProfile() {
        guard formIsValid else { return }
        isSubmitting = true

        // simulate a save; replace with your API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isSubmitting = false
            showSuccess = true
            // TODO: send {fullName, username, password, bio} to your backend
        }
    }
}
