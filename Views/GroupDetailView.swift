//
//  GroupDetailView.swift
//
//

import SwiftUI

struct GroupDetailView: View {
    
    @EnvironmentObject var authViewModel: FirebaseAuthViewModel
    @EnvironmentObject var socialViewModel: FirebaseSocialViewModel
    @Environment(\.dismiss) var dismiss
    
    let group: Group
    
    @State private var selectedTab = 0
    @State private var messageText = ""
    @State private var showShareArticle = false
    @State private var leaveAlert = false
    @State private var groupMembers: [User] = []
    @State private var isLoadingMembers = false
    
    private var currentGroup: Group? {
        socialViewModel.groups.first { $0.id == group.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if isMember {
                    Button(action: { leaveAlert = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                            Text("Leave")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Group Header
            VStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
                
                Text(currentGroup?.name ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(currentGroup?.members.count ?? 0) members")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !isMember {
                    Button(action: joinGroup) {
                        Text("Join Group")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                } else {
                    Button(action: { }) {
                        Text("Member")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            
            Picker("", selection: $selectedTab) {
                Text("Chat").tag(0)
                Text("Articles").tag(1)
                Text("Members").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if isMember {
                if selectedTab == 0 {
                    chatView
                } else if selectedTab == 1 {
                    articlesView
                } else {
                    membersView
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Join the group to see content")
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .navigationTitle(currentGroup?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadGroupMembers()
        }
        .sheet(isPresented: $showShareArticle) {
            ShareArticleToGroupView(group: group)
        }
        .alert("Leave Group?", isPresented: $leaveAlert) {
            Button("Leave", role: .destructive) {
                leaveGroup()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var isMember: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return currentGroup?.members.contains(userId) ?? false
    }
    
    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if currentGroup?.messages.isEmpty ?? true {
                        Text("No messages yet. Start the conversation!")
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                    } else {
                        ForEach(currentGroup?.messages ?? [], id: \.id) { message in
                            MessageRowView(message: message, isCurrentUser: message.userId == authViewModel.currentUser?.id)
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            HStack {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.accentColor)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
    }
    
    private var articlesView: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if currentGroup?.sharedArticles.isEmpty ?? true {
                        Text("No articles shared yet")
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                    } else {
                        ForEach((currentGroup?.sharedArticles ?? []).reversed(), id: \.id) { article in
                            SharedArticleRowView(article: article)
                        }
                    }
                }
                .padding()
            }
            
            Button(action: { showShareArticle = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Share Article")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
    }
    
    private var membersView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isLoadingMembers {
                    ProgressView()
                        .padding(.top, 50)
                } else if groupMembers.isEmpty {
                    Text("No members found")
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                } else {
                    ForEach(groupMembers, id: \.id) { member in
                        NavigationLink(destination: UserProfileView(
                            user: member,
                            isOwnProfile: member.id == authViewModel.currentUser?.id
                        )) {
                            MemberRowView(member: member)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
    }
    
    
    
    private func loadGroupMembers() async {
        isLoadingMembers = true
        guard let memberIds = currentGroup?.members else {
            isLoadingMembers = false
            return
        }
        
        var loadedMembers: [User] = []
        for memberId in memberIds {
            if let user = await authViewModel.getUser(by: memberId) {
                loadedMembers.append(user)
            }
        }
        
        await MainActor.run {
            groupMembers = loadedMembers
            isLoadingMembers = false
        }
    }
    
    private func joinGroup() {
        guard let userId = authViewModel.currentUser?.id else { return }
        let groupId = group.id
        socialViewModel.joinGroup(groupId: groupId, userId: userId)
        
        // Reload members after a brief delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await loadGroupMembers()
        }
    }
    
    private func leaveGroup() {
        guard let userId = authViewModel.currentUser?.id else { return }
        let groupId = group.id

        socialViewModel.leaveGroup(groupId: groupId, userId: userId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }

    
    private func sendMessage() {
        guard let user = authViewModel.currentUser else { return }
        
        let userId = user.id
        let groupId = group.id
        
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        socialViewModel.sendMessage(
            groupId: groupId,
            userId: userId,
            userName: user.displayName,
            text: text
        )
        messageText = ""
    }
}

struct MessageRowView: View {
    let message: GroupMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.userName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
                
                Text(message.text)
                    .padding(10)
                    .background(isCurrentUser ? Color.accentColor : Color.gray.opacity(0.2))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(12)
                
                Text(message.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
}

struct SharedArticleRowView: View {
    let article: SharedArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.accentColor)
                Text(article.sharedByName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(article.sharedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(article.articleTitle)
                .font(.headline)
                .lineLimit(2)
            
            if let comment = article.comment, !comment.isEmpty {
                Text(comment)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.vertical, 4)
            }
            
            if let previewImg = article.ogImageURL,
               let url = URL(string: previewImg) {
                            
               AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(height: 160)
                .clipped()
                .cornerRadius(8)
            }

            if let previewTitle = article.ogTitle {
                Text(previewTitle)
                    .font(.headline)
            }

            if let previewDesc = article.ogDescription {
                Text(previewDesc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let url = URL(string: article.articleURL) {
                Link("Read Article", destination: url)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct MemberRowView: View {
    let member: User
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !member.bio.isEmpty {
                    Text(member.bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(member.followers.count) followers")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill.checkmark")
                            .font(.caption)
                        Text("\(member.following.count) following")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Haptics
// Light: tab switches
// Medium: likes
// Heavy: errors
