//
//  AuthService.swift
//  SecuritiesSimulation
//

import Foundation

protocol AuthServicing {
    func login(mail: String, password: String) async throws -> LoginResponse
}

final class AuthService: AuthServicing {

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func login(mail: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(mail: mail, password: password)
        do {
            return try await apiClient.post(path: "login", body: request)
        } catch let error as APIError {
            throw Self.authError(for: error)
        } catch {
            throw AuthError.unexpected
        }
    }

    private static func authError(for error: APIError) -> AuthError {
        switch error {
        case .httpError(let statusCode, _):
            switch statusCode {
            case 401, 403:
                return .invalidCredentials
            case 500...599:
                return .serviceUnavailable
            default:
                return .unexpected
            }
        case .transportError:
            return .serviceUnavailable
        case .invalidURL, .invalidResponse, .encodingError, .decodingError:
            return .unexpected
        }
    }
}
