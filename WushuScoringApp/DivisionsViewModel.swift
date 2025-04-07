import Foundation
import SwiftUI

class DivisionsViewModel: ObservableObject {
    @Published var divisions: [Division] = []
    @Published var selectedDivision: Division?
    @Published var errorMessage: String?

    func fetchDivisions() {
        NetworkManager.shared.request("divisions") { (result: Result<[Division], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let divisions):
                    self.divisions = divisions
                    self.selectedDivision = divisions.first(where: { $0.isActive })
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func selectDivision(_ division: Division) {
        // Mark only one division as active in the UI
        divisions = divisions.map {
            Division(id: $0.id, name: $0.name, isActive: $0.id == division.id)
        }
        selectedDivision = division
    }

    func saveActiveDivision(completion: @escaping (Bool) -> Void) {
        guard let division = selectedDivision else { return }
        let parameters: [String: Any] = ["division_id": division.id]

        NetworkManager.shared.request("divisions/set-active", method: .post, parameters: parameters) { (result: Result<Division, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let updated):
                    print("✅ Active division saved: \(updated.name)")
                    self.selectDivision(updated)
                    completion(true)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
}
