//
//  Models.swift
//
//  WITHOUT FirebaseFirestoreSwift dependency
//

import Foundation

// MARK: - User Model

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    var displayName: String
    var bio: String
    var profileImageURL: String?
    var followers: [String]
    var following: [String]
    
    init(id: String = UUID().uuidString,
         email: String,
         displayName: String = "",
         bio: String = "") {
        self.id = id
        self.email = email
        self.displayName = displayName.isEmpty ? email.components(separatedBy: "@").first ?? email : displayName
        self.bio = bio
        self.followers = []
        self.following = []
    }
}

// MARK: - UserArticle Model

fileprivate let relativeDateFormatter = RelativeDateTimeFormatter()

struct UserArticle: Codable, Identifiable, Equatable {
    let id: String
    let authorId: String
    let authorName: String
    let title: String
    let content: String
    let imageURL: String?
    let videoURL: String?
    let isLocalMedia: Bool
    let createdAt: Date
    var likes: [String]
    var comments: [Comment]
    var keywords: [String]
    
    init(id: String = UUID().uuidString,
         authorId: String,
         authorName: String,
         title: String,
         content: String,
         imageURL: String? = nil,
         videoURL: String? = nil,
         isLocalMedia: Bool = false,
         createdAt: Date = Date(),
         keywords: [String] = []) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.title = title
        self.content = content
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.isLocalMedia = isLocalMedia
        self.createdAt = createdAt
        self.likes = []
        self.comments = []
        self.keywords = keywords
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Comment Model

struct Comment: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let userName: String
    let text: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         userName: String,
         text: String,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.text = text
        self.createdAt = createdAt
    }
}

// MARK: - Group Model

struct Group: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var description: String
    let creatorId: String
    var members: [String]
    var messages: [GroupMessage]
    var sharedArticles: [SharedArticle]
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         creatorId: String,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.creatorId = creatorId
        self.members = [creatorId]
        self.messages = []
        self.sharedArticles = []
        self.createdAt = createdAt
    }
}

// MARK: - GroupMessage Model

struct GroupMessage: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let userName: String
    let text: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         userName: String,
         text: String,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.text = text
        self.createdAt = createdAt
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - SharedArticle Model

struct SharedArticle: Codable, Identifiable, Equatable {
    let id: String
    let sharedBy: String
    let sharedByName: String
    let articleTitle: String
    let articleURL: String
    let sharedAt: Date
    let comment: String?

    // metadata fields
    let ogTitle: String?
    let ogDescription: String?
    let ogImageURL: String?

    
    init(id: String = UUID().uuidString,
         sharedBy: String,
         sharedByName: String,
         articleTitle: String,
         articleURL: String,
         comment: String? = nil,
         ogTitle: String? = nil,
         ogDescription: String? = nil,
         ogImageURL: String? = nil,
         sharedAt: Date = Date()) {
        self.id = id
        self.sharedBy = sharedBy
        self.sharedByName = sharedByName
        self.articleTitle = articleTitle
        self.articleURL = articleURL
        self.sharedAt = sharedAt
        self.comment = comment
        
        // metadata
        self.ogTitle = ogTitle
        self.ogDescription = ogDescription
        self.ogImageURL = ogImageURL
    }
}
