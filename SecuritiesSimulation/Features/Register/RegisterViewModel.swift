//
//  RegisterViewModel.swift
//  SecuritiesSimulation
//

import Foundation
import Combine

/// Screen state, validation, and registration orchestration for the
/// register screen.
///
/// Depends only on `AuthServicing` — never on its concrete type, `APIError`,
/// or HTTP details. `AppCoordinator` supplies the dependency and decides
/// what happens after `onRegisterSucceeded`.
@MainActor
final class RegisterViewModel {

    @Published private(set) var isRegisterEnabled: Bool = false
    @Published private(set) var nicknameErrorMessage: String?
    @Published private(set) var mailErrorMessage: String?
    @Published private(set) var passwordErrorMessage: String?
    @Published private(set) var confirmPasswordErrorMessage: String?
    @Published private(set) var generalErrorMessage: String?
    @Published private(set) var isLoading: Bool = false

    /// Invoked after a successful register response. The register endpoint
    /// returns the created user only (no session tokens), so this does not
    /// start a session — `AppCoordinator` decides what happens next.
    var onRegisterSucceeded: ((RegisterResponse) -> Void)?

    private(set) var nickname: String = ""
    private(set) var mail: String = ""
    private(set) var password: String = ""
    private(set) var confirmPassword: String = ""

    private let authService: AuthServicing

    init(authService: AuthServicing) {
        self.authService = authService
    }

    func nicknameDidChange(_ text: String) {
        nickname = text
        nicknameErrorMessage = Self.validateNickname(text)
        generalErrorMessage = nil
        updateRegisterEnabled()
    }

    func mailDidChange(_ text: String) {
        mail = text
        mailErrorMessage = Self.validateMail(text)
        generalErrorMessage = nil
        updateRegisterEnabled()
    }

    func passwordDidChange(_ text: String) {
        password = text
        passwordErrorMessage = Self.validatePassword(text)
        confirmPasswordErrorMessage = Self.validateConfirmPassword(confirmPassword, password: text)
        generalErrorMessage = nil
        updateRegisterEnabled()
    }

    func confirmPasswordDidChange(_ text: String) {
        confirmPassword = text
        confirmPasswordErrorMessage = Self.validateConfirmPassword(text, password: password)
        generalErrorMessage = nil
        updateRegisterEnabled()
    }

    func registerButtonTapped() {
        nicknameErrorMessage = Self.validateNickname(nickname, allowEmpty: false)
        mailErrorMessage = Self.validateMail(mail, allowEmpty: false)
        passwordErrorMessage = Self.validatePassword(password, allowEmpty: false)
        confirmPasswordErrorMessage = Self.validateConfirmPassword(confirmPassword, password: password, allowEmpty: false)
        updateRegisterEnabled()
        guard isRegisterEnabled, !isLoading else { return }

        isLoading = true
        generalErrorMessage = nil

        Task {
            await performRegister()
        }
    }

    private func performRegister() async {
        do {
            let response = try await authService.register(mail: mail, password: password, nickname: nickname)
            isLoading = false
            onRegisterSucceeded?(response)
        } catch let authError as AuthError {
            isLoading = false
            generalErrorMessage = Self.message(for: authError)
        } catch {
            isLoading = false
            generalErrorMessage = Self.genericFailureMessage
        }
    }

    private func updateRegisterEnabled() {
        isRegisterEnabled = !nickname.isEmpty
            && !mail.isEmpty
            && !password.isEmpty
            && !confirmPassword.isEmpty
            && Self.validateNickname(nickname) == nil
            && Self.validateMail(mail) == nil
            && Self.validatePassword(password) == nil
            && Self.validateConfirmPassword(confirmPassword, password: password) == nil
    }

    private static func validateNickname(_ value: String, allowEmpty: Bool = true) -> String? {
        if value.isEmpty { return allowEmpty ? nil : "請輸入暱稱" }
        return nil
    }

    private static func validateMail(_ value: String, allowEmpty: Bool = true) -> String? {
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

    private static func validateConfirmPassword(_ value: String, password: String, allowEmpty: Bool = true) -> String? {
        if value.isEmpty { return allowEmpty ? nil : "請再次輸入密碼" }
        return value == password ? nil : "兩次輸入的密碼不一致"
    }

    private static let genericFailureMessage = "註冊失敗，請稍後再試"

    private static func message(for error: AuthError) -> String {
        switch error {
        case .mailAlreadyExists:
            return "此帳號已被註冊"
        case .serviceUnavailable:
            return "無法連線到伺服器，請稍後再試"
        case .invalidCredentials, .unexpected:
            return genericFailureMessage
        }
    }
}
