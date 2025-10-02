//
//  OurNewsApp.swift
//
//  Firebase Integrated Version
//

import SwiftUI
import FirebaseCore

@main
struct OurNewsApp: App {
    
    // Initialize Firebase
    init() {
        FirebaseApp.configure()
    }
    
    @StateObject var articleBookmarkVM = ArticleBookmarkViewModel.shared
    @StateObject var authViewModel = FirebaseAuthViewModel()
    @StateObject var socialViewModel = FirebaseSocialViewModel.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(articleBookmarkVM)
                .environmentObject(authViewModel)
                .environmentObject(socialViewModel)
        }
    }
}

// MARK: - App Configuration
// Target: iOS 16+
// Architecture: MVVM

// MARK: - App Configuration
// Target: iOS 16+
// Architecture: MVVM
