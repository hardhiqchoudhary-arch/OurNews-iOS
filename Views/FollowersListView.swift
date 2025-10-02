//
//  FollowersListView.swift
//
//
//  Shows list of followers for a user
//

import SwiftUI

struct FollowersListView: View {
    
    @EnvironmentObject var authViewModel: FirebaseAuthViewModel
    
    let followerIds: [String]
    let title: String
    
    @State private var followers: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        SwiftUI.Group {
            if isLoading {
                ProgressView()
            } else if followers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No \(title.lowercased()) yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(followers, id: \.id) { follower in
                        NavigationLink(destination: UserProfileView(
                            user: follower,
                            isOwnProfile: follower.id == authViewModel.currentUser?.id
                        )) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(follower.displayName)
                                        .font(.headline)
                                    
                                    if !follower.bio.isEmpty {
                                        Text(follower.bio)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Text("\(follower.followers.count) followers")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(follower.following.count) following")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadFollowers()
        }
    }
    
    private func loadFollowers() async {
        isLoading = true
        var loadedFollowers: [User] = []
        
        for followerId in followerIds {
            if let user = await authViewModel.getUser(by: followerId) {
                loadedFollowers.append(user)
            }
        }
        
        await MainActor.run {
            followers = loadedFollowers.sorted { $0.displayName < $1.displayName }
            isLoading = false
        }
    }
}
