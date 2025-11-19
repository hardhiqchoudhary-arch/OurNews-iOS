//
//  CreateArticleView.swift
//  OurNews
//
//  Created by Hardhiq Choudhary on 01/11/25.
//

import SwiftUI

struct CreateArticleView: View {
    
    @EnvironmentObject var authViewModel: FirebaseAuthViewModel
    @EnvironmentObject var socialViewModel: FirebaseSocialViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var videoURL: String = ""
    @State private var showAlert = false
    
    // Camera/Photo picker states
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showMediaOptions = false
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $content)
                            .frame(minHeight: 150)
                        
                        if content.isEmpty {
                            Text("Describe the incident or write your article...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                } header: {
                    Text("Article Details")
                }
                
                Section {
                    // Display captured/selected image
                    if let image = selectedImage {
                        VStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                            
                            Button(role: .destructive) {
                                selectedImage = nil
                            } label: {
                                Text("Remove Photo")
                            }
                        }
                    }
                    
                    // Media capture buttons
                    Button {
                        showMediaOptions = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Add Photo / Video")
                            Spacer()
                        }
                    }
                    
                    TextField("Or paste video URL", text: $videoURL)
                        .autocapitalization(.none)
                } header: {
                    Text("Media")
                } footer: {
                    Text("Capture incident with camera or add from photo library")
                }
                
                if isUploading {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 10) {
                                ProgressView()
                                Text("Uploading image...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
                
                Section {
                    Button(action: createArticle) {
                        HStack {
                            Spacer()
                            Text(isUploading ? "Publishing..." : "Publish Article")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty || isUploading)
                }
            }
            .navigationTitle("Report Incident")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isUploading)
                }
            }
            .confirmationDialog("Add Media", isPresented: $showMediaOptions) {
                Button("Take Photo / Video") {
                    showCamera = true
                }
                Button("Choose from Library") {
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showImagePicker) {
                PHPickerRepresentable(selectedImage: $selectedImage)
            }
            .alert("Success", isPresented: $showAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your article has been published!")
            }
        }
    }
    
    private func createArticle() {
        guard let user = authViewModel.currentUser else { return }
        let userId = user.id
        
        isUploading = true
        
        Task {
            let trimmedVideoURL = videoURL.trimmingCharacters(in: .whitespacesAndNewlines)
            
            await socialViewModel.createArticle(
                title: title,
                content: content,
                image: selectedImage,
                videoURL: trimmedVideoURL.isEmpty ? nil : trimmedVideoURL,
                authorId: userId,
                authorName: user.displayName
            )
            
            await MainActor.run {
                isUploading = false
                showAlert = true
            }
        }
    }
}

struct CreateArticleView_Previews: PreviewProvider {
    static var previews: some View {
        CreateArticleView()
            .environmentObject(FirebaseAuthViewModel())
            .environmentObject(FirebaseSocialViewModel.shared)
    }
}
