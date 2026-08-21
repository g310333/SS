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

    /// The "股票" tab's own push stack, set up in `handleAuthSuccess`.
    /// Stock detail / order screens push here rather than onto
    /// `navigationController`, so they stay scoped to that tab and don't
    /// cover the bottom tab bar.
    private var stockNavigationController: UINavigationController?

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
        let tabBarController = makeMainTabBarController()
        navigationController.setViewControllers([tabBarController], animated: true)
    }

    /// Builds the post-login root: a bottom tab bar with 股票／持有股票／個人.
    /// Only the 股票 tab needs its own push stack (for stock detail and
    /// order screens), tracked via `stockNavigationController`.
    private func makeMainTabBarController() -> UITabBarController {
        let homeViewModel = HomeViewModel(stockService: container.stockService, stockGroupService: container.stockGroupService)
        let homeViewController = HomeViewController(viewModel: homeViewModel)
        homeViewController.onSelectStock = { [weak self] stock in
            self?.showStockDetail(stock: stock)
        }
        let stockNav = UINavigationController(rootViewController: homeViewController)
        stockNav.setNavigationBarHidden(true, animated: false)
        stockNav.tabBarItem = UITabBarItem(title: "股票", image: UIImage(systemName: "chart.bar"), tag: 0)
        stockNavigationController = stockNav

        let holdingsNav = UINavigationController(rootViewController: HoldingsViewController())
        holdingsNav.setNavigationBarHidden(true, animated: false)
        holdingsNav.tabBarItem = UITabBarItem(title: "持有股票", image: UIImage(systemName: "briefcase"), tag: 1)

        let profileNav = UINavigationController(rootViewController: ProfileViewController())
        profileNav.setNavigationBarHidden(true, animated: false)
        profileNav.tabBarItem = UITabBarItem(title: "個人", image: UIImage(systemName: "person.circle"), tag: 2)

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [stockNav, holdingsNav, profileNav]
        tabBarController.tabBar.tintColor = MaterialPalette.primary
        return tabBarController
    }

    private func showStockDetail(stock: Stock) {
        let viewModel = StockDetailViewModel(stock: stock, stockGroupService: container.stockGroupService)
        let detailViewController = StockDetailViewController(
            viewModel: viewModel,
            stockGroupService: container.stockGroupService
        )
        detailViewController.onPlaceOrder = { [weak self] stock in
            self?.showOrder(stock: stock)
        }
        stockNavigationController?.pushViewController(detailViewController, animated: true)
    }

    private func showOrder(stock: Stock) {
        let viewModel = OrderViewModel(stock: stock, tradeService: container.tradeService)
        let orderViewController = OrderViewController(viewModel: viewModel)
        stockNavigationController?.pushViewController(orderViewController, animated: true)
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
