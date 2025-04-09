import Foundation
import SwiftUI

class ParticipantsViewModel: ObservableObject {
    @Published var participants: [Participant] = []
    @Published var activeParticipant: Participant?
    @Published var onDeckParticipant: Participant?
    @Published var errorMessage: String?

    func fetchParticipants(for divisionName: String?) {
        NetworkManager.shared.request("participants") { (result: Result<[Participant], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let participants):
                    let filtered = divisionName != nil
                        ? participants.filter { $0.divisions.contains(divisionName!) }
                        : participants

                    self.participants = filtered.sorted { $0.name < $1.name }
                    self.fetchTournamentDetails()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // ✅ New: Fetch active and on-deck from tournament-details
    func fetchTournamentDetails() {
        NetworkManager.shared.request("tournament-details") { (result: Result<TournamentDetails, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let details):
                    self.activeParticipant = self.participants.first(where: { $0.id == details.activeId })
                    self.onDeckParticipant = self.participants.first(where: { $0.id == details.onDeckId })
                case .failure(let error):
                    self.errorMessage = "Failed to fetch tournament details: \(error.localizedDescription)"
                }
            }
        }
    }

    func setActiveParticipant(_ participant: Participant) {
        guard participant.id != onDeckParticipant?.id else {
            self.errorMessage = "Participant cannot be both Active and On-Deck."
            return
        }
        activeParticipant = participant
    }

    func setOnDeckParticipant(_ participant: Participant) {
        guard participant.id != activeParticipant?.id else {
            self.errorMessage = "Participant cannot be both Active and On-Deck."
            return
        }
        onDeckParticipant = participant
    }

    // ✅ New: Save both active and on-deck using POST
    func saveTournamentDetails() {
        guard let activeId = activeParticipant?.id,
              let onDeckId = onDeckParticipant?.id,
              activeId != onDeckId else {
            self.errorMessage = "Active and On-Deck participants must be different"
            return
        }

        let updates = [
            ("Active_ID", activeId),
            ("OnDeck_ID", onDeckId)
        ]

        let group = DispatchGroup()
        var postError: Error?

        for (argument, value) in updates {
            group.enter()
            let parameters: [String: Any] = [
                "argument": argument,
                "value": value
            ]

            NetworkManager.shared.request("tournament-details", method: .post, parameters: parameters) { (result: Result<EmptyResponse, Error>) in
                if case .failure(let error) = result {
                    postError = error
                }
                group.leave()
            }

        }

        group.notify(queue: .main) {
            if let error = postError {
                self.errorMessage = "Error saving participant selection: \(error.localizedDescription)"
            } else {
                print("✅ Successfully saved active and on-deck participants")
            }
        }
    }
}
