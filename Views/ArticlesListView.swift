//
//  ArticlesListView.swift
//  OurNews
//
//  Created by Hardhiq Choudhary on 20/11/25.
//
//  Shows all articles by a specific user
//

import SwiftUI

struct ArticlesListView: View {
    
    @EnvironmentObject var socialViewModel: FirebaseSocialViewModel
    
    let userId: String
    let userName: String
    
    @State private var selectedArticle: UserArticle?
    
    var body: some View {
        SwiftUI.Group {   // <-- FIX HERE
            if userArticles.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No articles yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(userName) hasn't posted any articles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(userArticles, id: \.id) { article in
                            UserArticleRowView(article: article)
                                .onTapGesture {
                                    selectedArticle = article
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("\(userName)'s Articles")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
    }
    
    private var userArticles: [UserArticle] {
        socialViewModel.getArticles(by: userId)
            .sorted { $0.createdAt > $1.createdAt }
    }
}
