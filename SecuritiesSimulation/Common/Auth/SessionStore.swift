//
//  SessionStore.swift
//  SecuritiesSimulation
//

import Foundation
import Security

struct Session: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
}

enum SessionStoreError: Error {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
}

protocol SessionStoring {
    func save(_ session: Session) throws
    func load() throws -> Session?
    func clear() throws
}

/// Persists the auth session in the Keychain. Tokens are credentials and
/// must not be written to UserDefaults or disk in plain text. Every
/// Keychain call's `OSStatus` is checked; failures are surfaced as
/// `SessionStoreError` rather than swallowed.
final class KeychainSessionStore: SessionStoring {

    private let service = "ai.app.alex.SecuritiesSimulation.auth"
    private let account = "session"

    func save(_ session: Session) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(session)
        } catch {
            throw SessionStoreError.encodingFailed(error)
        }

        let deleteStatus = SecItemDelete(query() as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw SessionStoreError.deleteFailed(deleteStatus)
        }

        var attributes = query()
        attributes[kSecValueData as String] = data
        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw SessionStoreError.saveFailed(addStatus)
        }
    }

    func load() throws -> Session? {
        var lookupQuery = query()
        lookupQuery[kSecReturnData as String] = true
        lookupQuery[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(lookupQuery as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw SessionStoreError.loadFailed(status)
        }
        guard let data = result as? Data else {
            return nil
        }

        do {
            return try JSONDecoder().decode(Session.self, from: data)
        } catch {
            throw SessionStoreError.decodingFailed(error)
        }
    }

    func clear() throws {
        let status = SecItemDelete(query() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SessionStoreError.deleteFailed(status)
        }
    }

    private func query() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
