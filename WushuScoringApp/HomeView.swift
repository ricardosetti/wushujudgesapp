import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var socketManager: SocketManager

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let role = authManager.userRole {
                    switch role {
                    case "head_judge":
                        VStack(spacing: 16) {
                            Text("Welcome, \(authManager.username ?? "Head Judge")")
                                .font(.title2)
                                .padding(.bottom, 20)

                            NavigationLink(destination: DivisionsView()) {
                                Text("Manage Divisions")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }

                            NavigationLink(destination: ParticipantsView()) {
                                Text("Manage Participants")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }

                            NavigationLink(destination: HeadJudgeView()) {
                                Text("Full Head Judge Panel")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }

                    default:
                        Text("Unknown role: \(role)")
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                Button(action: {
                    authManager.logout()
                }) {
                    Text("Logout")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Wushu Judges")
            .onAppear {
                socketManager.connect()
            }
            .onDisappear {
                socketManager.disconnect()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthManager.shared)
            .environmentObject(SocketManager.shared)
    }
}
