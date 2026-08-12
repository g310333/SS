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

    init(apiClient: APIClient = URLSessionAPIClient()) {
        self.apiClient = apiClient
    }

    func login(mail: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(mail: mail, password: password)
        return try await apiClient.post(path: "login", body: request)
    }
}
