import Foundation

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var isAuthenticated: Bool = false
    @Published var userRole: String?
    @Published var username: String?

    private init() {}

    func login(token: String, role: String, username: String) {
        NetworkManager.shared.setToken(token)
        self.isAuthenticated = true
        self.userRole = role
        self.username = username
    }

    func logout() {
        NetworkManager.shared.setToken(nil)
        self.isAuthenticated = false
        self.userRole = nil
        self.username = nil
    }
}
