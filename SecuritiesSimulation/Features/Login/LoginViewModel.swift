//
//  LoginViewModel.swift
//  SecuritiesSimulation
//

import Foundation
import Combine

/// Screen state, validation, and login orchestration for the login screen.
///
/// Depends only on `AuthServicing`/`SessionStoring` — never on their
/// concrete types, `APIError`, or HTTP details. `AppCoordinator` supplies
/// the dependencies and decides what happens after `onLoginSucceeded`.
@MainActor
final class LoginViewModel {

    @Published private(set) var isLoginEnabled: Bool = false
    @Published private(set) var usernameErrorMessage: String?
    @Published private(set) var passwordErrorMessage: String?
    @Published private(set) var generalErrorMessage: String?
    @Published private(set) var isLoading: Bool = false

    /// Invoked after a successful login response and once the session has
    /// been persisted. Does not decide app navigation itself.
    var onLoginSucceeded: ((AuthenticatedUser) -> Void)?

    private(set) var username: String = ""
    private(set) var password: String = ""

    private let authService: AuthServicing
    private let sessionStore: SessionStoring

    init(authService: AuthServicing, sessionStore: SessionStoring) {
        self.authService = authService
        self.sessionStore = sessionStore
    }

    func usernameDidChange(_ text: String) {
        username = text
        usernameErrorMessage = Self.validateUsername(text)
        generalErrorMessage = nil
        updateLoginEnabled()
    }

    func passwordDidChange(_ text: String) {
        password = text
        passwordErrorMessage = Self.validatePassword(text)
        generalErrorMessage = nil
        updateLoginEnabled()
    }

    func loginButtonTapped() {
        usernameErrorMessage = Self.validateUsername(username, allowEmpty: false)
        passwordErrorMessage = Self.validatePassword(password, allowEmpty: false)
        updateLoginEnabled()
        guard isLoginEnabled, !isLoading else { return }

        isLoading = true
        generalErrorMessage = nil

        Task {
            await performLogin()
        }
    }

    private func performLogin() async {
        do {
            let response = try await authService.login(mail: username, password: password)
            let session = Session(accessToken: response.accessToken, refreshToken: response.refreshToken)
            try sessionStore.save(session)
            isLoading = false
            onLoginSucceeded?(response.user)
        } catch let authError as AuthError {
            isLoading = false
            generalErrorMessage = Self.message(for: authError)
        } catch {
            // Covers SessionStoreError (save failed) and anything else
            // unexpected — never enter the success flow without a session.
            isLoading = false
            generalErrorMessage = Self.genericFailureMessage
        }
    }

    private func updateLoginEnabled() {
        isLoginEnabled = !username.isEmpty
            && !password.isEmpty
            && Self.validateUsername(username) == nil
            && Self.validatePassword(password) == nil
    }

    private static func validateUsername(_ value: String, allowEmpty: Bool = true) -> String? {
        if value.isEmpty { return allowEmpty ? nil : "請輸入帳號" }
        let regex = "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"
        let isValid = NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: value)
        return isValid ? nil : "請輸入有效的 Email 格式"
    }

    private static func validatePassword(_ value: String, allowEmpty: Bool = true) -> String? {
        if value.isEmpty { return allowEmpty ? nil : "請輸入密碼" }
        guard value.count > 8 else {
            return "密碼長度需超過 8 個字元"
        }
        let hasUppercase = value.contains { $0.isUppercase }
        let hasLowercase = value.contains { $0.isLowercase }
        let hasDigit = value.contains { $0.isNumber }
        guard hasUppercase, hasLowercase, hasDigit else {
            return "密碼需同時包含大寫、小寫英文字母與數字"
        }
        return nil
    }

    private static let genericFailureMessage = "登入失敗，請稍後再試"

    private static func message(for error: AuthError) -> String {
        switch error {
        case .invalidCredentials:
            return "帳號或密碼錯誤"
        case .serviceUnavailable:
            return "無法連線到伺服器，請稍後再試"
        case .unexpected:
            return genericFailureMessage
        }
    }
}
