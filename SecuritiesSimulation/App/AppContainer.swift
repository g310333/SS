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
    let stockGroupService: StockGroupServicing
    let tradeService: TradeServicing

    init() {
        let sessionStore = KeychainSessionStore()
        self.sessionStore = sessionStore
        let apiClient = URLSessionAPIClient(baseURL: AppConfiguration.apiBaseURL, sessionStore: sessionStore)
        self.apiClient = apiClient
        self.authService = AuthService(apiClient: apiClient)
        self.stockService = StockService(apiClient: apiClient)
        self.stockGroupService = StockGroupService(apiClient: apiClient)
        self.tradeService = TradeService(apiClient: apiClient)
    }
}
