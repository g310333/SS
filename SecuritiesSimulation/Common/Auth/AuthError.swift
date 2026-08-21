//
//  AuthError.swift
//  SecuritiesSimulation
//

import Foundation

/// Auth-domain errors surfaced to the Login feature. Networking details
/// (HTTP status codes, transport/decoding failures) are translated into
/// these cases by `AuthService` and must not leak any further up.
enum AuthError: Error {
    case invalidCredentials
    case mailAlreadyExists
    case serviceUnavailable
    case unexpected
}
