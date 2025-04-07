import Foundation
import Alamofire

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://157.245.9.25:5000"
    private var token: String?

    private init() {}

    func login(username: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let parameters: [String: String] = [
            "username": username,
            "password": password
        ]

        AF.request("\(baseURL)/auth/login", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseDecodable(of: LoginResponse.self) { response in
                switch response.result {
                case .success(let loginResponse):
                    self.token = loginResponse.token
                    completion(.success(loginResponse.token))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    func setToken(_ token: String?) {
        self.token = token
    }

    func getToken() -> String? {
        return token
    }

    func request<T: Decodable>(_ endpoint: String, method: HTTPMethod = .get, parameters: Parameters? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        var headers: HTTPHeaders?
        if let token = token {
            headers = ["Authorization": "Bearer \(token)"]
        }

        AF.request("\(baseURL)/\(endpoint)", method: method, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseData { response in
                if let data = response.data {
                    let rawResponse = String(data: data, encoding: .utf8) ?? "No readable data"
                    print("📦 Raw JSON response from \(endpoint):")
                    print(rawResponse)
                }

                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        // Removed keyDecodingStrategy to avoid interference with CodingKeys
                        let decoded = try decoder.decode(T.self, from: data)
                        completion(.success(decoded))
                    } catch {
                        print("❌ Decoding failed for \(endpoint): \(error)")
                        completion(.failure(error))
                    }
                case .failure(let error):
                    if response.response?.statusCode == 401 {
                        self.token = nil
                        completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token expired"])))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
    }
}

struct LoginResponse: Decodable {
    let token: String
}
