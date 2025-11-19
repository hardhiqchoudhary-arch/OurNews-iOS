//
//  UserArticleRowView.swift
//
//

import SwiftUI
import AVKit

struct UserArticleRowView: View {
    
    @EnvironmentObject var authViewModel: FirebaseAuthViewModel
    @EnvironmentObject var socialViewModel: FirebaseSocialViewModel
    
    let article: UserArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Author info
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.accentColor)
                
                Text(article.authorName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(article.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // MARK: - Media (Video first, then image)

            if let videoURL = article.videoURL,
               let url = URL(string: videoURL) {

                VideoRowPlayer(url: url)
                    .frame(height: 220)
                    .cornerRadius(10)
            }
            else if let imageURL = article.imageURL {

                if article.isLocalMedia {
                    if let image = MediaManager.shared.loadImage(filename: imageURL) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 220)
                            .clipped()
                            .cornerRadius(10)
                    }
                } else if let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(ProgressView())
                        }
                    }
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(10)
                }
            }
            
            // Title and Content
            Text(article.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(article.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Keywords
            if !article.keywords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(article.keywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundColor(.accentColor)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Actions
            HStack(spacing: 20) {
                Button(action: { toggleLike() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                        Text("\(article.likes.count)")
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                    Text("\(article.comments.count)")
                        .font(.caption)
                }
                .foregroundColor(.primary)
                
                if article.isLocalMedia {
                    Spacer()
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var isLiked: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return article.likes.contains(userId)
    }
    
    private func toggleLike() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let articleId = article.id
        socialViewModel.toggleLike(articleId: articleId, userId: userId)
    }
}

struct VideoRowPlayer: View {
    @State private var player: AVPlayer?
    let url: URL

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                ProgressView()
                    .onAppear {
                        player = AVPlayer(url: url)
                    }
            }
        }
    }
}


struct UserArticleRowView_Previews: PreviewProvider {
    static var previews: some View {
        UserArticleRowView(article: UserArticle(
            authorId: "123",
            authorName: "Test User",
            title: "Test Article",
            content: "Test content"
        ))
        .environmentObject(FirebaseAuthViewModel())
        .environmentObject(FirebaseSocialViewModel.shared)
    }
}

// MARK: - User Article Row
// Shows: thumbnail, title, author, likes count
