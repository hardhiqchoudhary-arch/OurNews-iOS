//
//  UserProfileView.swift
//
//

import SwiftUI

struct UserProfileView: View {
    
    @EnvironmentObject var authViewModel: FirebaseAuthViewModel
    @EnvironmentObject var socialViewModel: FirebaseSocialViewModel
    
    let user: User
    let isOwnProfile: Bool
    
    @State private var showEditProfile = false
    @State private var selectedArticle: UserArticle?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Profile Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                    
                    Text(user.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !user.bio.isEmpty {
                        Text(user.bio)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    HStack(spacing: 30) {
                        // Articles - clickable
                        NavigationLink(destination: ArticlesListView(
                            userId: user.id,
                            userName: user.displayName
                        )) {
                            VStack {
                                Text("\(userArticles.count)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Articles")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Followers - clickable
                        NavigationLink(destination: FollowersListView(
                            followerIds: user.followers,
                            title: "Followers"
                        )) {
                            VStack {
                                Text("\(user.followers.count)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Following - clickable
                        NavigationLink(destination: FollowersListView(
                            followerIds: user.following,
                            title: "Following"
                        )) {
                            VStack {
                                Text("\(user.following.count)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 8)
                    
                    if isOwnProfile {
                        Button(action: { showEditProfile = true }) {
                            Text("Edit Profile")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    } else {
                        Button(action: toggleFollow) {
                            Text(isFollowing ? "Unfollow" : "Follow")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(isFollowing ? Color.gray.opacity(0.2) : Color.accentColor)
                                .foregroundColor(isFollowing ? .primary : .white)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                Divider()
                
                // Articles Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Articles")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if userArticles.isEmpty {
                        Text("No articles yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(userArticles, id: \.id) { article in
                            UserArticleRowView(article: article)
                                .onTapGesture {
                                    selectedArticle = article
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle(isOwnProfile ? "My Profile" : "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(user: user)
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
    }
    
    // MARK: - Computed Properties
    
    private var userArticles: [UserArticle] {
        let userId = user.id
        return socialViewModel.getArticles(by: userId)
    }
    
    private var isFollowing: Bool {
        guard let currentUser = authViewModel.currentUser else {return false}
        return currentUser.following.contains(user.id)
    }
    
    // MARK: - Methods
    
    private func toggleFollow() {
        let profileUserId = user.id
        
        Task {
            if isFollowing {
                await authViewModel.unfollowUser(followingId: profileUserId)
            } else {
                await authViewModel.followUser(followingId: profileUserId)
            }
        }
    }
}
