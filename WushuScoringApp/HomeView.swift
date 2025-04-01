//
//  HomeView.swift
//  WushuScoringApp
//
//  Created by Setti on 4/1/25.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var socketManager: SocketManager

    var body: some View {
        NavigationView {
            VStack {
                if let role = authManager.userRole {
                    switch role {
//                    case "admin":
//                        NavigationLink("Admin Panel", destination: AdminView())
                    case "head_judge":
                        NavigationLink("Head Judge Panel", destination: HeadJudgeView())
//                    case "judge_a":
//                        if authManager.username == "judgea1" {
//                            NavigationLink("Judge A1 Panel", destination: JudgeA1View())
//                        } else {
//                            NavigationLink("Judge A2 Panel", destination: JudgeA2View())
//                        }
//                    case "judge_b":
//                        if authManager.username == "judgeb1" {
//                            NavigationLink("Judge B1 Panel", destination: JudgeB1View())
//                        } else {
//                            NavigationLink("Judge B2 Panel", destination: JudgeB2View())
//                        }
                    default:
                        Text("Unknown role")
                    }
                }

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
                .padding()
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
