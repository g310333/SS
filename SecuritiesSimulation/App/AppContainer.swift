//
//  AppContainer.swift
//  SecuritiesSimulation
//

import Foundation

/// Assembles and owns the app's shared service instances. This is the only
/// place concrete `Service`/`Client` types should be constructed; features
/// depend on the protocols only.
@MainActor
final class AppContainer {

    let apiClient: APIClient
    let authService: AuthServicing
    let sessionStore: SessionStoring
    let stockService: StockServicing

    init() {
        let apiClient = URLSessionAPIClient(baseURL: AppConfiguration.apiBaseURL)
        self.apiClient = apiClient
        self.authService = AuthService(apiClient: apiClient)
        self.sessionStore = KeychainSessionStore()
        self.stockService = StockService(apiClient: apiClient)
    }
}
