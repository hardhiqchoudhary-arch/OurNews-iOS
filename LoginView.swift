//
//  LoginView.swift
//
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var FirebaseAuthViewModel: FirebaseAuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("OurNews")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to continue")
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Password", text: $password)
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
                
                if isLoading {
                    ProgressView()
                        .padding()
                }
                
                Button(action: login) {
                    Text(isLoading ? "Logging in..." : "Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                
                Button(action: { showSignUp = true }) {
                    Text("Don't have an account? Sign Up")
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
            }
            .padding()
            .navigationTitle("Login")
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
    
    private func login() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            FirebaseAuthViewModel.errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        
        Task {
            await FirebaseAuthViewModel.login(email: trimmedEmail, password: trimmedPassword)
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(FirebaseAuthViewModel())
    }
}

// MARK: - Validation
// Min password length: 8
// Requires: uppercase, number
