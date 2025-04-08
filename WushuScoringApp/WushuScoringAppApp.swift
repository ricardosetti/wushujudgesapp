import SwiftUI

@main
struct WushuScoringAppApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var socketManager = SocketManager.shared
    @StateObject private var tournamentContext = TournamentContext() // 👈 Add this

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(socketManager)
                .environmentObject(tournamentContext) // 👈 Inject here
        }
    }
}
