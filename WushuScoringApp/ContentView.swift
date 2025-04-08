import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var socketManager: SocketManager

    var body: some View {
        if authManager.isAuthenticated {
            HomeView()
        } else {
            LoginView()
        }
    }
}
