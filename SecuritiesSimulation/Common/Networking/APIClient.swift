//
//  APIClient.swift
//  SecuritiesSimulation
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case encodingError(Error)
    case decodingError(Error)
    case transportError(Error)
}

protocol APIClient {
    func post<Request: Encodable, Response: Decodable>(path: String, body: Request) async throws -> Response
    func get<Response: Decodable>(path: String) async throws -> Response
}

/// Minimal JSON-over-HTTP client. All app services should go through this
/// rather than talking to `URLSession` directly.
final class URLSessionAPIClient: APIClient {

    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    func post<Request: Encodable, Response: Decodable>(path: String, body: Request) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }

        return try await send(request)
    }

    func get<Response: Decodable>(path: String) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await send(request)
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transportError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
