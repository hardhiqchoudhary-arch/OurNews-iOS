//
//  CreateGroupView.swift
//  OurNews
//
//  Created by Hardhiq Choudhary on 11/11/25.
//

import SwiftUI

struct CreateGroupView: View {
    
    @EnvironmentObject var authViewModel: FirebaseAuthViewModel
    @EnvironmentObject var socialViewModel: FirebaseSocialViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Group Name", text: $groupName)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $groupDescription)
                            .frame(minHeight: 100)
                        
                        if groupDescription.isEmpty {
                            Text("Describe your group...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                } header: {
                    Text("Group Information")
                }
                
                Section {
                    Button(action: createGroup) {
                        HStack {
                            Spacer()
                            Text("Create Group")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(groupName.isEmpty || groupDescription.isEmpty)
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Success", isPresented: $showAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your group has been created!")
            }
        }
    }
    
    private func createGroup() {
        guard let user = authViewModel.currentUser else
        { return }
        
        let userId = user.id
        
        socialViewModel.createGroup(
            name: groupName,
            description: groupDescription,
            creatorId: userId
        )
        
        showAlert = true
    }
}

struct CreateGroupView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGroupView()
            .environmentObject(FirebaseAuthViewModel())
            .environmentObject(FirebaseSocialViewModel.shared)
    }
}
