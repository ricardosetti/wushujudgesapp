import SwiftUI

struct HeadJudgeView: View {
    @EnvironmentObject var socketManager: SocketManager
    @State private var divisions: [Division] = []
    @State private var selectedDivision: Division?
    @State private var participants: [Participant] = []
    @State private var selectedParticipant: Participant?
    @State private var scores: [Score] = []
    @State private var calculatedScores: (finalA: Double, finalB: Double, final: Double)?
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }

            // Select Division
            Picker("Select Division", selection: $selectedDivision) {
                Text("None").tag(nil as Division?)
                ForEach(divisions) { division in
                    Text(division.name).tag(division as Division?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            if selectedDivision != nil {
                Button(action: {
                    setActiveDivision()
                }) {
                    Text("Set as Active Division")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }

            // Select Participant
            if let division = selectedDivision, division.isActive {
                Picker("Select Participant", selection: $selectedParticipant) {
                    Text("None").tag(nil as Participant?)
                    ForEach(participants) { participant in
                        Text(participant.name).tag(participant as Participant?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()

                if selectedParticipant != nil {
                    Button(action: {
                        setActiveParticipant()
                    }) {
                        Text("Set as Active Participant")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }

            // Display Scores
            if selectedParticipant != nil {
                if scores.isEmpty {
                    Text("No scores submitted for \(selectedParticipant?.name ?? "")")
                        .font(.headline)
                        .padding()
                } else {
                    Text("Scores for Participant \(selectedParticipant?.name ?? "")")
                        .font(.headline)
                        .padding()

                    List(scores.indices, id: \.self) { index in
                        let score = scores[index]
                        VStack(alignment: .leading) {
                            Text("Judge: \(score.judge)")
                            Text("Score: \(score.score, specifier: "%.2f")")
                        }
                    }

                    // Calculate Scores
                    Button(action: {
                        calculateScores()
                    }) {
                        Text("Calculate Scores")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Display Calculated Scores
                    if let calculated = calculatedScores {
                        Text("FinalA: \(calculated.finalA, specifier: "%.2f")")
                            .font(.subheadline)
                            .padding(.top)
                        Text("FinalB: \(calculated.finalB, specifier: "%.2f")")
                            .font(.subheadline)
                        Text("Final: \(calculated.final, specifier: "%.2f")")
                            .font(.subheadline)
                            .padding(.bottom)
                    }

                    // Publish Final Score
                    Button(action: {
                        publishFinalScore()
                    }) {
                        Text("Publish Final Score")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
            }
        }
        .navigationTitle("Head Judge")
        .onAppear {
            fetchDivisions()
            fetchParticipants()
        }
        .onChange(of: selectedDivision) { _ in
            fetchActiveParticipant()
        }
        .onReceive(socketManager.$scoreSubmitted.compactMap { $0 }) { _ in
            fetchScores()
        }
        .onReceive(socketManager.$scoreUpdated) { _ in
            fetchScores()
        }
        .onReceive(socketManager.$tournamentDetailsUpdated.compactMap { $0 }) { details in
            if let activeId = details["Active_ID"] as? Int {
                if let participant = participants.first(where: { $0.id == activeId }) {
                    selectedParticipant = participant
                    fetchScores()
                } else {
                    selectedParticipant = nil
                }
            }
        }
    }

    func fetchDivisions() {
        NetworkManager.shared.request("divisions") { (result: Result<[Division], Error>) in
            switch result {
            case .success(let divisions):
                self.divisions = divisions
                if let activeDivision = divisions.first(where: { $0.isActive }) {
                    self.selectedDivision = activeDivision
                    fetchActiveParticipant()
                }
            case .failure(let error):
                let errorMessage = (error as NSError?)?.localizedDescription ?? "An unknown error occurred while fetching divisions"
                self.errorMessage = errorMessage
            }
        }
    }

    func fetchParticipants() {
        NetworkManager.shared.request("participants") { (result: Result<[Participant], Error>) in
            switch result {
            case .success(let participants):
                self.participants = participants
                fetchActiveParticipant()
            case .failure(let error):
                let errorMessage = (error as NSError?)?.localizedDescription ?? "An unknown error occurred while fetching participants"
                self.errorMessage = errorMessage
            }
        }
    }

    func fetchActiveParticipant() {
        NetworkManager.shared.request("active-participant") { (result: Result<Participant?, Error>) in
            switch result {
            case .success(let activeParticipant):
                self.selectedParticipant = activeParticipant
                if activeParticipant != nil {
                    fetchScores()
                }
            case .failure(let error):
                let errorMessage = (error as NSError?)?.localizedDescription ?? "An unknown error occurred while fetching active participant"
                self.errorMessage = errorMessage
                self.selectedParticipant = nil
            }
        }
    }

    func setActiveDivision() {
        guard let division = selectedDivision else { return }
        let parameters: [String: Any] = ["division_id": division.id]
        NetworkManager.shared.request("divisions/set-active", method: .post, parameters: parameters) { (result: Result<Division, Error>) in
            switch result {
            case .success(let updatedDivision):
                self.selectedDivision = updatedDivision
                socketManager.emit("activeDivisionUpdated", ["division_id": updatedDivision.id])
                fetchActiveParticipant()
            case .failure(let error):
                let errorMessage = (error as NSError?)?.localizedDescription ?? "An unknown error occurred while setting active division"
                self.errorMessage = errorMessage
            }
        }
    }

    func setActiveParticipant() {
        guard let participant = selectedParticipant else { return }
        let parameters: [String: Any] = ["participant_id": participant.id]
        NetworkManager.shared.request("active-participant", method: .post, parameters: parameters) { (result: Result<Participant, Error>) in
            switch result {
            case .success(let updatedParticipant):
                self.selectedParticipant = updatedParticipant
                fetchScores()
            case .failure(let error):
                let errorMessage = (error as NSError?)?.localizedDescription ?? "An unknown error occurred while setting active participant"
                self.errorMessage = errorMessage
            }
        }
    }

    func fetchScores() {
        guard let participantId = selectedParticipant?.id else { return }
        NetworkManager.shared.request("scores/participant/\(participantId)") { (result: Result<[Score], Error>) in
            switch result {
            case .success(let scores):
                // Filter scores to only include A1, A2, B1, B2
                self.scores = scores.filter { ["A1", "A2", "B1", "B2"].contains($0.judge) }
            case .failure(let error):
                let errorMessage = (error as NSError?)?.localizedDescription ?? "An unknown error occurred while fetching scores"
                self.errorMessage = errorMessage
            }
        }
    }

    func calculateScores() {
        guard let participantId = selectedParticipant?.id else {
            errorMessage = "No participant selected"
            return
        }
        guard selectedDivision != nil else {
            errorMessage = "No active division selected"
            return
        }

        // Extract scores for A1, A2, B1, B2
        let a1Score = scores.first(where: { $0.judge == "A1" })?.score ?? 0.0
        let a2Score = scores.first(where: { $0.judge == "A2" })?.score ?? 0.0
        let b1Score = scores.first(where: { $0.judge == "B1" })?.score ?? 0.0
        let b2Score = scores.first(where: { $0.judge == "B2" })?.score ?? 0.0

        // Check if all required scores are present
        if a1Score == 0.0 || a2Score == 0.0 || b1Score == 0.0 || b2Score == 0.0 {
            errorMessage = "Missing scores from one or more judges (A1, A2, B1, B2)"
            return
        }

        // Calculate FinalA, FinalB, and Final
        let finalA = (a1Score + a2Score) / 2
        let finalB = (b1Score + b2Score) / 2
        let final = finalA + finalB

        // Update UI with calculated scores
        self.calculatedScores = (finalA: finalA, finalB: finalB, final: final)

        // Save the calculated scores to the backend
        saveCalculatedScore(participantId: participantId, judge: "FinalA", score: finalA) { success in
            if success {
                print("Successfully saved FinalA")
                saveCalculatedScore(participantId: participantId, judge: "FinalB", score: finalB) { success in
                    if success {
                        print("Successfully saved FinalB")
                        saveCalculatedScore(participantId: participantId, judge: "Final", score: final) { success in
                            if success {
                                print("Successfully saved Final")
                                // Refresh scores to include the new FinalA, FinalB, and Final scores
                                fetchScores()
                            } else {
                                print("Failed to save Final")
                            }
                        }
                    } else {
                        print("Failed to save FinalB")
                    }
                }
            } else {
                print("Failed to save FinalA")
            }
        }
    }

    func saveCalculatedScore(participantId: Int, judge: String, score: Double, completion: @escaping (Bool) -> Void) {
        let parameters: [String: Any] = [
            "participant_id": participantId,
            "judge": judge,
            "score": score
        ]

        print("Saving score for \(judge): \(parameters)")
        NetworkManager.shared.request("scores", method: .post, parameters: parameters) { (result: Result<ScoreResponse, Error>) in
            switch result {
            case .success(let response):
                if let error = response.error {
                    self.errorMessage = "Failed to save \(judge) score: \(error)"
                    print("Error saving \(judge): \(error)")
                    completion(false)
                } else {
                    print("Successfully saved \(judge) score")
                    completion(true)
                }
            case .failure(let error):
                let errorMessage = (error as NSError?)?.localizedDescription ?? "An unknown error occurred while saving score"
                self.errorMessage = "Failed to save \(judge) score: \(errorMessage)"
                print("Error saving \(judge): \(errorMessage)")
                completion(false)
            }
        }
    }

    func publishFinalScore() {
        guard let participantId = selectedParticipant?.id else {
            errorMessage = "No participant selected"
            return
        }
        guard selectedDivision != nil else {
            errorMessage = "No active division selected"
            return
        }
        guard let calculated = calculatedScores else {
            errorMessage = "Please calculate scores before publishing"
            return
        }

        // Prepare all required scores
        let requiredJudges = ["A1", "A2", "B1", "B2", "FinalA", "FinalB", "Final"]
        var publishData: [[String: Any]] = []

        // Add A1, A2, B1, B2 scores
        for judge in ["A1", "A2", "B1", "B2"] {
            if let score = scores.first(where: { $0.judge == judge })?.score {
                publishData.append(["judge": judge, "score": score])
            }
        }

        // Add FinalA, FinalB, and Final scores
        publishData.append(["judge": "FinalA", "score": calculated.finalA])
        publishData.append(["judge": "FinalB", "score": calculated.finalB])
        publishData.append(["judge": "Final", "score": calculated.final])

        // Validate that all required scores are present
        let presentJudges = publishData.map { $0["judge"] as! String }
        let missingJudges = requiredJudges.filter { !presentJudges.contains($0) }
        if !missingJudges.isEmpty {
            errorMessage = "Cannot publish score: Missing scores from \(missingJudges.joined(separator: ", "))"
            return
        }

        // Prepare the request payload
        let parameters: [String: Any] = [
            "participant_id": participantId,
            "scores": publishData
        ]

        NetworkManager.shared.request("published-scores", method: .post, parameters: parameters) { (result: Result<[PublishedScore], Error>) in
            switch result {
            case .success(let publishedScores):
                print("✅ Successfully published scores: \(publishedScores)")
                socketManager.emit("scorePublished", ["participant_id": participantId, "scores": publishData])
                self.scores = []
                self.calculatedScores = nil
                self.selectedParticipant = nil
                self.fetchActiveParticipant()
            case .failure(let error):
                let errorMessage = (error as NSError?)?.localizedDescription ?? "An unknown error occurred while publishing score"
                self.errorMessage = "Failed to publish final score: \(errorMessage)"
                print("❌ Failed to decode response for published-scores: \(errorMessage)")
            }

        }
    }
}

struct HeadJudgeView_Previews: PreviewProvider {
    static var previews: some View {
        HeadJudgeView()
            .environmentObject(SocketManager.shared)
    }
}
