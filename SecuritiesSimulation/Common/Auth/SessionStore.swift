//
//  SessionStore.swift
//  SecuritiesSimulation
//

import Foundation
import Security

protocol SessionStoring {
    func save(accessToken: String, refreshToken: String)
    func clear()
}

/// Persists auth tokens in the Keychain. Tokens are credentials and must
/// not be written to UserDefaults or disk in plain text.
final class KeychainSessionStore: SessionStoring {

    private let service = "ai.app.alex.SecuritiesSimulation.auth"

    func save(accessToken: String, refreshToken: String) {
        write(accessToken, forKey: "accessToken")
        write(refreshToken, forKey: "refreshToken")
    }

    func clear() {
        delete(forKey: "accessToken")
        delete(forKey: "refreshToken")
    }

    private func write(_ value: String, forKey key: String) {
        let query = queryForItem(key: key)
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(attributes as CFDictionary, nil)
    }

    private func delete(forKey key: String) {
        SecItemDelete(queryForItem(key: key) as CFDictionary)
    }

    private func queryForItem(key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
