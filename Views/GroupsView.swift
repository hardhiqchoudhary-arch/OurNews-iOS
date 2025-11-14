//
//  GroupsView.swift
//  OurNews
//
//  Created by Hardhiq Choudhary on 16/11/25.
//

import SwiftUI

struct GroupsView: View {
    
    @EnvironmentObject var FirebaseAuthViewModel: FirebaseAuthViewModel
    @EnvironmentObject var FirebaseSocialViewModel: FirebaseSocialViewModel
    
    @State private var showCreateGroup = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("My Groups")) {
                    if userGroups.isEmpty {
                        Text("You haven't joined any groups yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(userGroups) { group in
                            NavigationLink(destination: GroupDetailView(group: group)) {
                                GroupRowView(group: group)
                            }
                        }
                    }
                }
                
                Section(header: Text("All Groups")) {
                    if availableGroups.isEmpty {
                        Text("No other groups available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(availableGroups) { group in
                            NavigationLink(destination: GroupDetailView(group: group)) {
                                GroupRowView(group: group)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .navigationBarItems(
                trailing: Button(action: { showCreateGroup = true }) {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                }
            )
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView()
            }
        }
    }
    
    private var userGroups: [Group] {
        guard let userId = FirebaseAuthViewModel.currentUser?.id else { return [] }
        return FirebaseSocialViewModel.getUserGroups(userId: userId)
    }
    
    private var availableGroups: [Group] {
        guard let userId = FirebaseAuthViewModel.currentUser?.id else { return [] }
        return FirebaseSocialViewModel.groups.filter { !$0.members.contains(userId) }
    }
}

struct GroupRowView: View {
    let group: Group
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.accentColor)
                
                Text(group.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(group.members.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(group.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
