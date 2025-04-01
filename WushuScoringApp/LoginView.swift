import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                Text("Wushu Judges App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 40)

                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top, 10)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: {
                    login()
                }) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .padding()
            .navigationTitle("Login")
        }
    }

    func login() {
        NetworkManager.shared.login(username: username, password: password) { result in
            switch result {
            case .success(let token):
                if let decodedToken = decodeToken(token) {
                    authManager.login(token: token, role: decodedToken["role"] as! String, username: decodedToken["username"] as! String)
                } else {
                    errorMessage = "Failed to decode token"
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    func decodeToken(_ token: String) -> [String: Any]? {
        let components = token.split(separator: ".")
        guard components.count == 3 else { return nil }
        let payload = String(components[1])
        let padding = String(repeating: "=", count: (4 - payload.count % 4) % 4)
        let paddedPayload = payload + padding
        guard let data = Data(base64Encoded: paddedPayload.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager.shared)
    }
}
