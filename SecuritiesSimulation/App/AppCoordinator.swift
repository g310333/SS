//
//  AppCoordinator.swift
//  SecuritiesSimulation
//

import UIKit

/// Owns root navigation and App-level flow decisions (e.g. what to show
/// after a successful login). Screens report what happened; the coordinator
/// decides what happens next.
@MainActor
final class AppCoordinator {

    private let container: AppContainer
    private let navigationController: UINavigationController

    init(container: AppContainer, navigationController: UINavigationController) {
        self.container = container
        self.navigationController = navigationController
    }

    func start() {
        showLogin()
    }

    private func showLogin() {
        let viewModel = LoginViewModel(
            authService: container.authService,
            sessionStore: container.sessionStore
        )
        viewModel.onLoginSucceeded = { [weak self] user in
            self?.handleLoginSuccess(user: user)
        }

        let loginViewController = LoginViewController(viewModel: viewModel)
        navigationController.setViewControllers([loginViewController], animated: false)
    }

    /// No home screen exists yet, so a placeholder acknowledgement stands
    /// in for "navigate to the post-login flow".
    private func handleLoginSuccess(user: AuthenticatedUser) {
        let alert = UIAlertController(
            title: "登入成功",
            message: "歡迎，\(user.mail)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        navigationController.present(alert, animated: true)
    }
}
