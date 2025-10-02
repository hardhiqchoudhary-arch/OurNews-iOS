//
//  FirebaseAuthViewModel.swift
//
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class FirebaseAuthViewModel: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String = ""
    @Published var currentUser: User?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        // Check if user is already logged in
        if let firebaseUser = auth.currentUser {
            isLoggedIn = true
            loadUserProfile(userId: firebaseUser.uid)
        }
    }
    
    // MARK: - Authentication
    
    func register(email: String, password: String, displayName: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        do {
            // Create Firebase Auth user
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Create user profile in Firestore
            let user = User(
                id: result.user.uid,
                email: email,
                displayName: displayName.isEmpty ? email.components(separatedBy: "@").first ?? email : displayName,
                bio: ""
            )
            
            try await saveUserProfile(user: user)
            
            self.currentUser = user
            self.isLoggedIn = true
            self.errorMessage = ""
            
        } catch let error as NSError {
            handleAuthError(error)
        }
    }
    
    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            loadUserProfile(userId: result.user.uid)
            isLoggedIn = true
            errorMessage = ""
            
        } catch let error as NSError {
            handleAuthError(error)
        }
    }
    
    func logout() {
        do {
            try auth.signOut()
            isLoggedIn = false
            currentUser = nil
            errorMessage = ""
        } catch {
            errorMessage = "Failed to logout: \(error.localizedDescription)"
        }
    }
    
    // MARK: - User Profile
    
    func loadUserProfile(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading user profile: \(error)")
                return
            }
            
            if let data = snapshot?.data() {
                var user = User(
                    id: userId,
                    email: data["email"] as? String ?? "",
                    displayName: data["displayName"] as? String ?? "",
                    bio: data["bio"] as? String ?? ""
                )
                
                user.followers = data["followers"] as? [String] ?? []
                user.following = data["following"] as? [String] ?? []
                
                DispatchQueue.main.async {
                    self.currentUser = user
                }
            }
        }
    }

    
    func saveUserProfile(user: User) async throws {
        let userId = user.id
        let userData: [String: Any] = [
            "email": user.email,
            "displayName": user.displayName,
            "bio": user.bio,
            "followers": user.followers,
            "following": user.following,
            "createdAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(userId).setData(userData, merge: true)
    }
    
    func updateProfile(displayName: String, bio: String) {
        guard var user = currentUser else { return }
        
        user.displayName = displayName
        user.bio = bio
        
        Task {
            do {
                try await saveUserProfile(user: user)
                await MainActor.run {
                    self.currentUser = user
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - User Management
    
    func getUser(by id: String) async -> User? {
        do {
            let snapshot = try await db.collection("users").document(id).getDocument()
            
            if let data = snapshot.data() {
                return User(
                    id: id,
                    email: data["email"] as? String ?? "",
                    displayName: data["displayName"] as? String ?? "",
                    bio: data["bio"] as? String ?? ""
                )
            }
        } catch {
            print("Error fetching user: \(error)")
        }
        return nil
    }
    
    func getAllUsers() async -> [User] {
        do {
            let snapshot = try await db.collection("users").getDocuments()
            
            return snapshot.documents.compactMap { doc in
                let data = doc.data()
                return User(
                    id: doc.documentID,
                    email: data["email"] as? String ?? "",
                    displayName: data["displayName"] as? String ?? "",
                    bio: data["bio"] as? String ?? ""
                )
            }
        } catch {
            print("Error fetching users: \(error)")
            return []
        }
    }
    
    // MARK: - Follow System
    
    func followUser(followingId: String) async {
        guard let currentUser = currentUser else { return }
        let currentUserId = currentUser.id
              
        
        do {
            // Add to current user's following
            try await db.collection("users").document(currentUserId)
                .updateData([
                    "following": FieldValue.arrayUnion([followingId])
                ])
            
            // Add to other user's followers
            try await db.collection("users").document(followingId)
                .updateData([
                    "followers": FieldValue.arrayUnion([currentUserId])
                ])
            
            // Reload current user
            loadUserProfile(userId: currentUserId)
            
        } catch {
            errorMessage = "Failed to follow user: \(error.localizedDescription)"
        }
    }
    
    func unfollowUser(followingId: String) async {
        guard let currentUser = currentUser else { return }
        let currentUserId = currentUser.id  
        
        do {
            // Remove from current user's following
            try await db.collection("users").document(currentUserId)
                .updateData([
                    "following": FieldValue.arrayRemove([followingId])
                ])
            
            // Remove from other user's followers
            try await db.collection("users").document(followingId)
                .updateData([
                    "followers": FieldValue.arrayRemove([currentUserId])
                ])
            
            // Reload current user
            loadUserProfile(userId: currentUserId)
            
        } catch {
            errorMessage = "Failed to unfollow user: \(error.localizedDescription)"
        }
    }
    
    func isFollowing(userId: String) -> Bool {
        return currentUser?.following.contains(userId) ?? false
    }
    
    // MARK: - Error Handling
    
    private func handleAuthError(_ error: NSError) {
        switch AuthErrorCode(rawValue: error.code) {
        case .emailAlreadyInUse:
            errorMessage = "Account already exists. Please login."
        case .wrongPassword:
            errorMessage = "Username or password is incorrect"
        case .userNotFound:
            errorMessage = "Account does not exist. Please sign up first."
        case .invalidEmail:
            errorMessage = "Invalid email address"
        case .weakPassword:
            errorMessage = "Password is too weak. Use at least 6 characters."
        case .networkError:
            errorMessage = "Network error. Check your connection."
        default:
            errorMessage = error.localizedDescription
        }
    }
}
