import SwiftUI

struct ParticipantsView: View {
    @StateObject private var viewModel = ParticipantsViewModel()
    @EnvironmentObject var tournamentContext: TournamentContext


    var body: some View {
        VStack {
            if let error = viewModel.errorMessage {
                Text("⚠️ \(error)")
                    .foregroundColor(.red)
                    .padding()
            }

            List {
                ForEach(viewModel.participants) { participant in
                    HStack {
                        Text(participant.name)
                        Spacer()

                        Toggle("Active", isOn: Binding(
                            get: { viewModel.activeParticipant?.id == participant.id },
                            set: { isActive in
                                if isActive {
                                    viewModel.setActiveParticipant(participant)
                                }
                            }
                        ))
                        .labelsHidden()

                        Toggle("On Deck", isOn: Binding(
                            get: { viewModel.onDeckParticipant?.id == participant.id },
                            set: { isOnDeck in
                                if isOnDeck {
                                    viewModel.setOnDeckParticipant(participant)
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                }
            }

            Button("Save Active Participant") {
                viewModel.saveTournamentDetails()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .navigationTitle("Participants")
        .onAppear {
            viewModel.fetchParticipants()
        }
    }
}
