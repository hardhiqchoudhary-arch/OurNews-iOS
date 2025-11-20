//
//  FirebaseSocialViewModel.swift
//
//


import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class FirebaseSocialViewModel: ObservableObject {
    
    @Published var userArticles: [UserArticle] = []
    @Published var groups: [Group] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var articlesListener: ListenerRegistration?
    private var groupsListener: ListenerRegistration?
    
    static let shared = FirebaseSocialViewModel()
    
    private init() {
        setupListeners()
    }
    
    // MARK: - Real-time Listeners
    
    func setupListeners() {
        // Listen for articles changes
        articlesListener = db.collection("articles")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching articles: \(error)")
                    return
                }
                
                self.userArticles = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: UserArticle.self)
                } ?? []
            }
        
        // Listen for groups changes
        groupsListener = db.collection("groups")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching groups: \(error)")
                    return
                }
                
                self.groups = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Group.self)
                } ?? []
            }
    }
    
    deinit {
        articlesListener?.remove()
        groupsListener?.remove()
    }
    
    // MARK: - Articles (Local Storage for Images)
    
    func createArticle(
        title: String,
        content: String,
        image: UIImage?,
        videoURL: String?,
        authorId: String,
        authorName: String
    ) async {
        isLoading = true
        
        do {
            var imageURL: String? = nil
            var isLocalMedia = false
            
            // Save image locally if provided
            if let image = image {
                if let filename = MediaManager.shared.saveImage(image) {
                    imageURL = filename
                    isLocalMedia = true
                }
            }
            
            // Extract keywords from article content
            let keywords = EnhancedKeywordExtractor.shared.extractKeywordsSimple(
                title: title,
                description: nil,
                content: content,
                maxKeywords: 5
            )
            
            let article = UserArticle(
                authorId: authorId,
                authorName: authorName,
                title: title,
                content: content,
                imageURL: imageURL,
                videoURL: videoURL,
                isLocalMedia: isLocalMedia,
                keywords: keywords
            )
            
            try db.collection("articles").document(article.id).setData(from: article)
            
        } catch {
            print("Error creating article: \(error)")
        }
        
        isLoading = false
    }
    
    func getArticles(by authorId: String) -> [UserArticle] {
        return userArticles.filter { $0.authorId == authorId }
    }
    
    func getFollowingArticles(followingIds: [String]) -> [UserArticle] {
        return userArticles.filter { followingIds.contains($0.authorId) }
    }
    
    func getFeedArticles(for userId: String, followingIds: [String]) -> [UserArticle] {
        return userArticles.filter { article in
            article.authorId == userId || followingIds.contains(article.authorId)
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    
    func toggleLike(articleId: String, userId: String) {
        // Update local state immediately
        if let index = userArticles.firstIndex(where: { $0.id == articleId }) {
            if userArticles[index].likes.contains(userId) {
                userArticles[index].likes.removeAll { $0 == userId }
            } else {
                userArticles[index].likes.append(userId)
            }
            
            // Trigger UI update
            objectWillChange.send()
        }

        // Then sync to Firestore in background
        let articleRef = db.collection("articles").document(articleId)

        if userArticles.first(where: { $0.id == articleId })?.likes.contains(userId) == true {
            articleRef.updateData([
                "likes": FieldValue.arrayUnion([userId])
            ])
        } else {
            articleRef.updateData([
                "likes": FieldValue.arrayRemove([userId])
            ])
        }
    }

    
    func addComment(articleId: String, userId: String, userName: String, text: String) {
        
        // ==== 1. Update local UI immediately ====
        if let index = userArticles.firstIndex(where: { $0.id == articleId }) {
            let newComment = Comment(userId: userId, userName: userName, text: text)
            userArticles[index].comments.append(newComment)
            
            // This forces SwiftUI to refresh immediately
            objectWillChange.send()
        }
        
        // ==== 2. Then sync to Firestore in background ====
        let comment = Comment(userId: userId, userName: userName, text: text)
        
        guard let commentData = try? Firestore.Encoder().encode(comment) else { return }
        
        db.collection("articles").document(articleId).updateData([
            "comments": FieldValue.arrayUnion([commentData])
        ])
    }

    
    func deleteArticle(articleId: String) async {
        // Get article to check for local image
        if let article = userArticles.first(where: { $0.id == articleId }),
           article.isLocalMedia,
           let imageFilename = article.imageURL {
            // Delete local image
            MediaManager.shared.deleteImage(filename: imageFilename)
        }
        
        // Delete article document
        do {
            try await db.collection("articles").document(articleId).delete()
        } catch {
            print("Error deleting article: \(error)")
        }
    }
    
    // MARK: - Groups
    
    func createGroup(name: String, description: String, creatorId: String) {
        let group = Group(name: name, description: description, creatorId: creatorId)
        
        do {
            try db.collection("groups").document(group.id).setData(from: group)
        } catch {
            print("Error creating group: \(error)")
        }
    }
    
    func joinGroup(groupId: String, userId: String) {
        db.collection("groups").document(groupId).updateData([
            "members": FieldValue.arrayUnion([userId])
        ])
    }
    
    func leaveGroup(groupId: String, userId: String) {

        // 1) Update local state
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].members.removeAll { $0 == userId }

            // Check if no members left
            if groups[index].members.isEmpty {
                // Remove from local list
                groups.remove(at: index)

                // Delete from Firestore
                db.collection("groups").document(groupId).delete { error in
                    if let error = error {
                        print("Error deleting empty group: \(error)")
                    } else {
                        print("Group deleted because it had 0 members")
                    }
                }

                return  // Stop here — no need to update members array
            }
        }

        // 2) Update Firestore members list
        db.collection("groups").document(groupId).updateData([
            "members": FieldValue.arrayRemove([userId])
        ])
    }
    
    func sendMessage(groupId: String, userId: String, userName: String, text: String) {
        let message = GroupMessage(userId: userId, userName: userName, text: text)
        
        guard let messageData = try? Firestore.Encoder().encode(message) else { return }
        
        db.collection("groups").document(groupId).updateData([
            "messages": FieldValue.arrayUnion([messageData])
        ])
    }
    
    func shareArticle(groupId: String, userId: String, userName: String, articleTitle: String, articleURL: String, comment: String?,ogTitle: String?, ogDescription: String?, ogImageURL: String?) {
        let sharedArticle = SharedArticle(
            sharedBy: userId,
            sharedByName: userName,
            articleTitle: articleTitle,
            articleURL: articleURL,
            comment: comment,
            ogTitle: ogTitle,
            ogDescription: ogDescription,
            ogImageURL: ogImageURL
        )
        
        guard let articleData = try? Firestore.Encoder().encode(sharedArticle) else { return }
        
        db.collection("groups").document(groupId).updateData([
            "sharedArticles": FieldValue.arrayUnion([articleData])
        ])
    }
    
    func getUserGroups(userId: String) -> [Group] {
        return groups.filter { $0.members.contains(userId) }
    }
    
    func deleteGroup(groupId: String) async {
        do {
            try await db.collection("groups").document(groupId).delete()
        } catch {
            print("Error deleting group: \(error)")
        }
    }
    // MARK: Metadata Fetching
        func fetchOGMetadata(from urlString: String, completion: @escaping (String?, String?, String?) -> Void) {
            guard let url = URL(string: urlString) else {
                completion(nil, nil, nil)
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data,
                      let html = String(data: data, encoding: .utf8) else {
                    completion(nil, nil, nil)
                    return
                }

                let title = self.matchMetaTag(html: html, property: "og:title")
                let description = self.matchMetaTag(html: html, property: "og:description")
                let image = self.matchMetaTag(html: html, property: "og:image")
                
                DispatchQueue.main.async {
                    completion(title, description, image)
                }
            }.resume()
        }

        private func matchMetaTag(html: String, property: String) -> String? {
            let pattern = "<meta[^>]*property=\"\(property)\"[^>]*content=\"([^\"]+)\""
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
            }
            return nil
        }
}

// MARK: - Firebase Social
// Collections: posts, likes, comments, shares
// Batched writes for consistency
