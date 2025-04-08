import SwiftUI

struct DivisionsView: View {
    @StateObject private var viewModel = DivisionsViewModel()
    @EnvironmentObject var tournamentContext: TournamentContext // ✅ Properly placed inside the struct

    var body: some View {
        VStack {
            if let error = viewModel.errorMessage {
                Text("⚠️ \(error)")
                    .foregroundColor(.red)
                    .padding()
            }

            List {
                ForEach(viewModel.divisions) { division in
                    HStack {
                        Text(division.name)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { division.id == viewModel.selectedDivision?.id },
                            set: { isOn in
                                if isOn {
                                    viewModel.selectDivision(division)
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                }
            }

            Button(action: {
                viewModel.saveActiveDivision { success in
                    if success {
                        tournamentContext.activeDivision = viewModel.selectedDivision // ✅ update context
                    } else {
                        print("❌ Failed to save active division")
                    }
                }
            }) {
                Text("Save Active Division")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Divisions")
        .onAppear {
            viewModel.fetchDivisions()
        }
    }
}
