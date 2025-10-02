//
//  SignUpView.swift
//
//

import SwiftUI

struct SignUpView: View {
    
    @EnvironmentObject var FirebaseAuthViewModel: FirebaseAuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email: String = ""
    @State private var displayName: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign up to get started")
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                if !FirebaseAuthViewModel.errorMessage.isEmpty {
                    Text(FirebaseAuthViewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: signUp) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Creating Account..." : "Sign Up")
                            .frame(minWidth: 150)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                
                Button(action: { dismiss() }) {
                    Text("Already have an account? Login")
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
            }
            .padding()
            .navigationTitle("Sign Up")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func signUp() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validation
        guard !trimmedEmail.isEmpty else {
            FirebaseAuthViewModel.errorMessage = "Email is required"
            return
        }
        
        guard !trimmedPassword.isEmpty else {
            FirebaseAuthViewModel.errorMessage = "Password is required"
            return
        }
        
        guard trimmedPassword == trimmedConfirmPassword else {
            FirebaseAuthViewModel.errorMessage = "Passwords do not match"
            return
        }
        
        guard trimmedPassword.count >= 6 else {
            FirebaseAuthViewModel.errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        
        Task {
            await FirebaseAuthViewModel.register(
                email: trimmedEmail,
                password: trimmedPassword,
                displayName: trimmedDisplayName
            )
            
            await MainActor.run {
                isLoading = false
                if FirebaseAuthViewModel.isLoggedIn {
                    dismiss()
                }
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(FirebaseAuthViewModel())
    }
}
