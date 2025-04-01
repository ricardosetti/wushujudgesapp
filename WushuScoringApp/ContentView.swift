import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var socketManager = SocketManager.shared

    var body: some View {
        if authManager.isAuthenticated {
            HomeView()
                .environmentObject(authManager)
                .environmentObject(socketManager)
        } else {
            LoginView()
                .environmentObject(authManager)
                .environmentObject(socketManager)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
