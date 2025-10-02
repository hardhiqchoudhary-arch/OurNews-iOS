//
//  UserSearchView.swift
//
//
//  Dedicated view for searching and finding users
//

import SwiftUI

struct UserSearchView: View {
    
    @EnvironmentObject var authViewModel: FirebaseAuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var users: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        SwiftUI.Group {   // <-- FIX HERE
            if isLoading {
                ProgressView()
            } else {
                List {
                    if filteredUsers.isEmpty && !searchText.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No users found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if searchText.isEmpty {
                        Section(header: Text("All Users")) {
                            ForEach(allUsersExceptCurrent, id: \.id) { user in
                                UserSearchRowView(user: user)
                            }
                        }
                    } else {
                        Section(header: Text("Search Results (\(filteredUsers.count))")) {
                            ForEach(filteredUsers, id: \.id) { user in
                                UserSearchRowView(user: user)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Search Users")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by name or email...")
        .task {
            await loadUsers()
        }
    }
    
    private var allUsersExceptCurrent: [User] {
        users.filter { $0.id != authViewModel.currentUser?.id }
            .sorted { $0.displayName < $1.displayName }
    }
    
    private var filteredUsers: [User] {
        let query = searchText.lowercased()
        
        return users.filter { user in
            user.id != authViewModel.currentUser?.id &&
            (user.displayName.lowercased().contains(query) ||
             user.email.lowercased().contains(query))
        }
        .sorted { user1, user2 in
            let starts1 = user1.displayName.lowercased().hasPrefix(query)
            let starts2 = user2.displayName.lowercased().hasPrefix(query)
            if starts1 != starts2 { return starts1 }  // start-with results first
            return user1.displayName < user2.displayName
        }
    }
    
    private func loadUsers() async {
        isLoading = true
        let loadedUsers = await authViewModel.getAllUsers()
        await MainActor.run {
            users = loadedUsers
            isLoading = false
        }
    }
}

struct UserSearchRowView: View {
    
    @EnvironmentObject var authViewModel: FirebaseAuthViewModel
    
    let user: User
    
    var body: some View {
        NavigationLink(destination: UserProfileView(
            user: user,
            isOwnProfile: user.id == authViewModel.currentUser?.id
        )) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 45))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.headline)
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !user.bio.isEmpty {
                        Text(user.bio)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(user.followers.count)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill.checkmark")
                                .font(.caption2)
                            Text("\(user.following.count)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if authViewModel.isFollowing(userId: user.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
        }
    }
}
