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
            self?.handleAuthSuccess(user: user)
        }

        let loginViewController = LoginViewController(viewModel: viewModel)
        loginViewController.onSignUpTapped = { [weak self] in
            self?.showRegister()
        }
        navigationController.setViewControllers([loginViewController], animated: false)
    }

    private func showRegister() {
        let viewModel = RegisterViewModel(authService: container.authService)
        viewModel.onRegisterSucceeded = { [weak self] user in
            self?.handleRegisterSuccess(user: user)
        }

        let registerViewController = RegisterViewController(viewModel: viewModel)
        registerViewController.onLoginTapped = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(registerViewController, animated: true)
    }

    private func handleAuthSuccess(user _: AuthenticatedUser) {
        let viewModel = HomeViewModel(stockService: container.stockService)
        let homeViewController = HomeViewController(viewModel: viewModel)
        homeViewController.onSelectStock = { [weak self] stock in
            self?.showStockDetail(stock: stock)
        }
        navigationController.setViewControllers([homeViewController], animated: true)
    }

    private func showStockDetail(stock: Stock) {
        let viewModel = StockDetailViewModel(stock: stock, stockGroupService: container.stockGroupService)
        let detailViewController = StockDetailViewController(
            viewModel: viewModel,
            stockGroupService: container.stockGroupService
        )
        navigationController.pushViewController(detailViewController, animated: true)
    }

    /// Registration returns the created user but no session tokens, so the
    /// user is sent back to log in rather than being signed in automatically.
    private func handleRegisterSuccess(user: RegisterResponse) {
        navigationController.popToRootViewController(animated: false)
        let alert = UIAlertController(
            title: "註冊成功",
            message: "歡迎，\(user.nickname)，請使用新帳號登入",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        navigationController.present(alert, animated: true)
    }
}
