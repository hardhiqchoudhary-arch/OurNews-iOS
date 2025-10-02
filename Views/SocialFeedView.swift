//
//  SocialFeedView.swift
//
//

import SwiftUI

struct SocialFeedView: View {
    
    @EnvironmentObject var authViewModel: FirebaseAuthViewModel
    @EnvironmentObject var socialViewModel: FirebaseSocialViewModel
    
    @State private var showCreateArticle = false
    @State private var selectedArticle: UserArticle?
    @State private var searchText = ""
    @State private var showSearchView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        
                        // Following articles
                        if !feedArticles.isEmpty {
                            ForEach(feedArticles, id: \.id) { article in
                                UserArticleRowView(article: article)
                                    .onTapGesture {
                                        selectedArticle = article
                                    }
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("No articles yet")
                                    .font(.headline)
                                
                                Text("Follow users to see their articles here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 100)
                        }
                    }
                    .padding(.vertical)
                }
                
                if !searchText.isEmpty {
                    UserSearchResultsView(searchText: searchText)
                }
            }
            .navigationTitle("Social Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: UserSearchView()) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search Users")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateArticle = true }) {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showCreateArticle) {
                CreateArticleView()
            }
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
            .searchable(text: $searchText, prompt: "Search users...")
        }
    }
    
    private var feedArticles: [UserArticle] {
        guard let currentUser = authViewModel.currentUser
            else {  return [] }
        
        let userId = currentUser.id

        return socialViewModel.getFeedArticles(
            for: userId,
            followingIds: currentUser.following
        )
    }
}

struct UserSearchResultsView: View {
    
    @EnvironmentObject var authViewModel: FirebaseAuthViewModel
    
    let searchText: String
    @State private var users: [User] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredUsers, id: \.id) { user in
                    NavigationLink(destination: destinationView(for: user)) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Results")
            .task {
                users = await authViewModel.getAllUsers()
            }
        }
    }
    
    private var filteredUsers: [User] {
        let query = searchText.lowercased()
        
        return users.filter { user in
            user.id != authViewModel.currentUser?.id &&
            (user.displayName.lowercased().contains(query) ||
             user.email.lowercased().contains(query))
        }
        .sorted { $0.displayName < $1.displayName }
    }
    
    private func destinationView(for user: User) -> some View {
        UserProfileView(
            user: user,
            isOwnProfile: user.id == authViewModel.currentUser?.id
        )
    }
}
