//
//  AuthModels.swift
//  SecuritiesSimulation
//

import Foundation

struct LoginRequest: Encodable {
    let mail: String
    let password: String
}

struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: AuthenticatedUser
}

struct AuthenticatedUser: Decodable {
    let id: Int
    let mail: String
}
