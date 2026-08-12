//
//  SceneDelegate.swift
//  SecuritiesSimulation
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        self.window = window

        let container = AppContainer()
        let coordinator = AppCoordinator(container: container, navigationController: navigationController)
        appCoordinator = coordinator
        coordinator.start()

        window.makeKeyAndVisible()
    }
}
