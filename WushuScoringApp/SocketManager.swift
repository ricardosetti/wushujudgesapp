import Foundation

import SocketIO

class SocketManager: ObservableObject {
    static let shared = SocketManager()
    private let manager: SocketIO.SocketManager
    private var socket: SocketIOClient!

    @Published var isConnected: Bool = false
    @Published var scorePublished: [String: Any]?
    @Published var activeDivisionUpdated: [String: Any]?
    @Published var tournamentDetailsUpdated: [String: Any]?
    @Published var scoreSubmitted: [String: Any]?
    @Published var scoreUpdated: [String: Any]? // Added for scoreUpdated event
    @Published var deductionUpdated: [String: Any]?

    private init() {
        manager = SocketIO.SocketManager(socketURL: URL(string: "http://157.245.9.25:5000")!, config: [.log(true), .forceWebsockets(true)])
        socket = manager.socket(forNamespace: "/")

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("Socket connected")
            self?.isConnected = true
        }

        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("Socket disconnected")
            self?.isConnected = false
        }

        socket.on("scorePublished") { [weak self] data, _ in
            if let dataDict = data.first as? [String: Any] {
                self?.scorePublished = dataDict
            }
        }

        socket.on("activeDivisionUpdated") { [weak self] data, _ in
            if let dataDict = data.first as? [String: Any] {
                self?.activeDivisionUpdated = dataDict
            }
        }

        socket.on("tournamentDetailsUpdated") { [weak self] data, _ in
            if let dataDict = data.first as? [String: Any] {
                self?.tournamentDetailsUpdated = dataDict
            }
        }

        socket.on("scoreSubmitted") { [weak self] data, _ in
            if let dataDict = data.first as? [String: Any] {
                self?.scoreSubmitted = dataDict
            }
        }

        socket.on("scoreUpdated") { [weak self] data, _ in
            if let dataDict = data.first as? [String: Any] {
                self?.scoreUpdated = dataDict
            }
        }

        socket.on("deductionUpdated") { [weak self] data, _ in
            if let dataDict = data.first as? [String: Any] {
                self?.deductionUpdated = dataDict
            }
        }
    }

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    func emit(_ event: String, _ data: [String: Any]) {
        socket.emit(event, data)
    }
}
