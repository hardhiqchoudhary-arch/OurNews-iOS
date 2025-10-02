//
//  MainTabView.swift
//
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NewsTabView()
                .tabItem {
                    Label("News", systemImage: "newspaper")
                }
            
            SocialFeedView()
                .tabItem {
                    Label("Social", systemImage: "person.2")
                }
            
            GroupsView()
                .tabItem {
                    Label("Groups", systemImage: "person.3")
                }
            
            SearchTabView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            BookmarkTabView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
            
            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}

// MARK: - Tab Structure
// 0: News
// 1: Search
// 2: Bookmarks
// 3: Profile

// MARK: - Tab Structure
// 0: News
// 1: Search
// 2: Bookmarks
// 3: Profile
