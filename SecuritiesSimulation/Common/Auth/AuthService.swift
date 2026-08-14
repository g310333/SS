//
//  AuthService.swift
//  SecuritiesSimulation
//

import Foundation

protocol AuthServicing {
    func login(mail: String, password: String) async throws -> LoginResponse
    func register(mail: String, password: String, nickname: String) async throws -> RegisterResponse
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
            throw Self.loginError(for: error)
        } catch {
            throw AuthError.unexpected
        }
    }

    func register(mail: String, password: String, nickname: String) async throws -> RegisterResponse {
        let request = RegisterRequest(mail: mail, password: password, nickname: nickname)
        do {
            return try await apiClient.post(path: "register", body: request)
        } catch let error as APIError {
            throw Self.registerError(for: error)
        } catch {
            throw AuthError.unexpected
        }
    }

    private static func loginError(for error: APIError) -> AuthError {
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

    private static func registerError(for error: APIError) -> AuthError {
        switch error {
        case .httpError(let statusCode, _):
            switch statusCode {
            case 409:
                return .mailAlreadyExists
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
