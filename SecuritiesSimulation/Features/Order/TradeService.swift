//
//  TradeService.swift
//  SecuritiesSimulation
//

import Foundation

protocol TradeServicing {
    func buy(stockCode: String, quantity: Int) async throws -> BuyTradeResult
}

final class TradeService: TradeServicing {

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func buy(stockCode: String, quantity: Int) async throws -> BuyTradeResult {
        do {
            let request = BuyTradeRequest(stockCode: stockCode, quantity: quantity)
            return try await apiClient.post(path: "trades/buy", body: request)
        } catch let error as APIError {
            throw Self.tradeError(for: error)
        } catch {
            throw TradeError.unexpected
        }
    }

    private static func tradeError(for error: APIError) -> TradeError {
        switch error {
        case .httpError(let statusCode, _):
            switch statusCode {
            case 500...599:
                return .serviceUnavailable
            default:
                return .unexpected
            }
        case .transportError:
            return .serviceUnavailable
        case .invalidURL, .invalidResponse, .encodingError, .decodingError:
            return .unexpected
        }
    }
}
