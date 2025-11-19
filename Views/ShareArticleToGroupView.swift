//
//  ShareArticleToGroupView.swift
//
//


import SwiftUI

struct ShareArticleToGroupView: View {
    
    @EnvironmentObject var authViewModel: FirebaseAuthViewModel
    @EnvironmentObject var socialViewModel: FirebaseSocialViewModel
    @Environment(\.dismiss) var dismiss
    
    let group: Group
    
    @State private var articleTitle: String = ""
    @State private var articleURL: String = ""
    @State private var articleComment: String = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Article Information")) {
                    TextField("Article Title", text: $articleTitle)
                    
                    TextField("Article URL", text: $articleURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    }
                
                Section {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $articleComment)
                            .padding(10)
                            .frame(minHeight: 400)
                            .background(Color.clear)

                        if articleComment.isEmpty {
                            Text("Write a comment...")
                                .foregroundColor(.gray)
                                .padding(.top, 16)
                                .padding(.leading, 14)
                        }
                    }
                }
                
                Section {
                    Button(action: shareArticle) {
                        HStack {
                            Spacer()
                            Text("Share to Group")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(articleTitle.isEmpty || articleURL.isEmpty)
                }
            }
            .navigationTitle("Share Article")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
            .alert("Success", isPresented: $showAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Article shared to \(group.name)!")
            }
        }
    }
    
    private func shareArticle() {
        // currentUser is Optional → correct to unwrap here
        guard let user = authViewModel.currentUser else { return }
        
        // id values are NON-optional → use them directly
        let groupId = group.id
        let userId = user.id
        
        socialViewModel.fetchOGMetadata(from: articleURL) { ogTitle, ogDesc, ogImg in
            socialViewModel.shareArticle(
                groupId: groupId,
                userId: userId,
                userName: user.displayName,
                articleTitle: articleTitle,
                articleURL: articleURL,
                comment: articleComment,
                ogTitle: ogTitle,
                ogDescription: ogDesc,
                ogImageURL: ogImg
            )
            
            showAlert = true
        }
    }
}

// MARK: - Share
// Share target: Group or Followers
// Max groups shown: 10
