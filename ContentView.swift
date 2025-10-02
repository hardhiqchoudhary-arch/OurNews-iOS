import SwiftUI

struct ContentView: View {
    @EnvironmentObject var FirebaseAuthViewModel: FirebaseAuthViewModel

    var body: some View {
        if FirebaseAuthViewModel.isLoggedIn {
            MainTabView()      // App after login
        } else {
            LoginView()        // Login screen
        }
    }
}

// MARK: - Color Constants
// Primary: Blue
// Secondary: Gray
// Accent: Orange
