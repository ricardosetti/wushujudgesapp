import Foundation

struct EmptyResponse: Decodable {}


struct Division: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name = "division_name"
        case isActive = "active"
    }
}

struct Participant: Decodable, Identifiable, Hashable {
    let id: Int
    let schoolId: Int
    let firstName: String
    let lastName: String
    let active: Bool?
    var name: String { "\(firstName) \(lastName)" }

    enum CodingKeys: String, CodingKey {
        case id
        case schoolId = "school_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case active
    }
}

struct TournamentDetails: Decodable {
    let activeId: Int?
    let onDeckId: Int?

    enum CodingKeys: String, CodingKey {
        case activeId = "Active_ID"
        case onDeckId = "OnDeck_ID"
    }
}

struct Score: Decodable {
    let judge: String
    let score: Double

    enum CodingKeys: String, CodingKey {
        case judge
        case score
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        judge = try container.decode(String.self, forKey: .judge)

        // Decode score as a String and convert to Double
        let scoreString = try container.decode(String.self, forKey: .score)
        guard let scoreValue = Double(scoreString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .score,
                in: container,
                debugDescription: "Expected a string that can be converted to Double, but got \(scoreString)"
            )
        }
        score = scoreValue
    }
}

struct ScoreResponse: Decodable {
    let id: Int?
    let participantId: Int?
    let judge: String?
    let score: Double?
    let createdAt: String?
    let divisionId: Int?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case id
        case participantId = "participant_id"
        case judge
        case score
        case createdAt = "created_at"
        case divisionId = "division_id"
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        participantId = try container.decodeIfPresent(Int.self, forKey: .participantId)
        judge = try container.decodeIfPresent(String.self, forKey: .judge)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        divisionId = try container.decodeIfPresent(Int.self, forKey: .divisionId)

        // Decode score as a String and convert to Double
        if let scoreString = try container.decodeIfPresent(String.self, forKey: .score) {
            score = Double(scoreString)
        } else {
            score = nil
        }
    }
}

struct PublishedScore: Decodable {
    let id: Int
    let participantId: Int
    let judge: String
    let score: Double
    let publishedAt: String
    let divisionId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case participantId = "participant_id"
        case judge
        case score
        case publishedAt = "published_at"
        case divisionId = "division_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        participantId = try container.decode(Int.self, forKey: .participantId)
        judge = try container.decode(String.self, forKey: .judge)
        publishedAt = try container.decode(String.self, forKey: .publishedAt)
        divisionId = try container.decode(Int.self, forKey: .divisionId)

        // Decode score as a String and convert to Double
        let scoreString = try container.decode(String.self, forKey: .score)
        guard let scoreValue = Double(scoreString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .score,
                in: container,
                debugDescription: "Expected a string that can be converted to Double, but got \(scoreString)"
            )
        }
        score = scoreValue
    }
}

struct PublishedScoreResponse: Decodable {
    var scores: [PublishedScore]?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case scores
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scores = try container.decodeIfPresent([PublishedScore].self, forKey: .scores)
        error = try container.decodeIfPresent(String.self, forKey: .error)

        // If scores is not present, try decoding the entire response as an array
        if scores == nil, container.allKeys.isEmpty {
            var arrayContainer = try decoder.unkeyedContainer()
            scores = try arrayContainer.decode([PublishedScore].self)
        }
    }
}
