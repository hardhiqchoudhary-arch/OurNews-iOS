//
//  ProfileTabView.swift
//  OurNews
//
//  Created by Hardhiq Choudhary on 01/11/25.
//

import SwiftUI

struct ProfileTabView: View {
    
    @EnvironmentObject var FirebaseAuthViewModel: FirebaseAuthViewModel
    
    var body: some View {
        NavigationView {
            if let currentUser = FirebaseAuthViewModel.currentUser {
                UserProfileView(user: currentUser, isOwnProfile: true)
                    .navigationBarItems(trailing: logoutButton)
            } else {
                Text("Loading...")
            }
        }
    }
    
    private var logoutButton: some View {
        Button(role: .destructive, action: {
            FirebaseAuthViewModel.logout()
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Logout")
            }
        }
    }
}
