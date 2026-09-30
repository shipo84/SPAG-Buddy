import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Talks to the `api` Edge Function (see backend/README.md).
struct APIClient: Sendable {
    let baseURL: URL
    var session: URLSession = .shared

    /// `nil` when `SPAG_API_BASE_URL` is not set, in which case the app works offline only.
    static let live: APIClient? = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SPAGBuddyAPIBaseURL") as? String,
              !value.isEmpty, !value.hasPrefix("$("),
              let url = URL(string: value), url.scheme == "https" || url.host == "localhost" else { return nil }
        return APIClient(baseURL: url)
    }()

    func join(classCode: String, avatarKey: String, pin: String) async throws -> JoinResponse {
        try await send("POST", "pupil/join", body: JoinRequest(classCode: classCode, avatarKey: avatarKey, pin: pin))
    }

    func uploadAttempts(_ attempts: [AttemptUpload], token: String) async throws -> AttemptUploadResponse {
        try await send("POST", "attempts", body: AttemptBatch(attempts: attempts), token: token)
    }

    func assignments(token: String) async throws -> [AssignmentDTO] {
        let response: AssignmentsResponse = try await send("GET", "assignments", token: token)
        return response.assignments
    }

    func contentManifest() async throws -> RemoteContentManifest {
        try await send("GET", "content/manifest")
    }

    func download(_ url: URL) async throws -> Data {
        let (data, response) = try await perform(URLRequest(url: url))
        guard (200..<300).contains(response.statusCode) else { throw APIError.server(response.statusCode) }
        return data
    }

    private func send<Response: Decodable>(_ method: String, _ path: String, token: String? = nil) async throws -> Response {
        try await send(method, path, body: Optional<AttemptBatch>.none, token: token)
    }

    private func send<Body: Encodable, Response: Decodable>(
        _ method: String,
        _ path: String,
        body: Body?,
        token: String? = nil
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder.api.encode(body)
        }

        let (data, response) = try await perform(request)
        if let error = APIError.from(status: response.statusCode, body: try? JSONDecoder.api.decode(APIErrorBody.self, from: data)) {
            throw error
        }
        return try JSONDecoder.api.decode(Response.self, from: data)
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.transport }
        return (data, http)
    }
}
