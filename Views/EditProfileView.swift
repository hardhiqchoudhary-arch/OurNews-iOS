//
//  EditProfileView.swift
//
//

import SwiftUI

struct EditProfileView: View {
    
    @EnvironmentObject var FirebaseAuthViewModel: FirebaseAuthViewModel
    @Environment(\.dismiss) var dismiss
    
    let user: User
    
    @State private var displayName: String = ""
    @State private var bio: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Display Name", text: $displayName)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $bio)
                            .frame(minHeight: 100)
                        
                        if bio.isEmpty {
                            Text("Write something about yourself...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                } header: {
                    Text("Profile Information")
                }
                
                Section {
                    Button(action: saveProfile) {
                        HStack {
                            Spacer()
                            Text("Save Changes")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                displayName = user.displayName
                bio = user.bio
            }
        }
    }
    
    private func saveProfile() {
        FirebaseAuthViewModel.updateProfile(displayName: displayName, bio: bio)
        dismiss()
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(user: User(email: "test@example.com", displayName: "Test User", bio: "Test bio"))
            .environmentObject(FirebaseAuthViewModel())
    }
}
