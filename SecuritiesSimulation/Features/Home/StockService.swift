//
//  StockService.swift
//  SecuritiesSimulation
//

import Foundation

protocol StockServicing {
    func fetchStocks() async throws -> [Stock]
    func fetchIndustries() async throws -> [Industry]
}

final class StockService: StockServicing {

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchStocks() async throws -> [Stock] {
        do {
            return try await apiClient.get(path: "stocks")
        } catch let error as APIError {
            throw Self.stockError(for: error)
        } catch {
            throw StockError.unexpected
        }
    }

    func fetchIndustries() async throws -> [Industry] {
        do {
            return try await apiClient.get(path: "industries")
        } catch let error as APIError {
            throw Self.stockError(for: error)
        } catch {
            throw StockError.unexpected
        }
    }

    private static func stockError(for error: APIError) -> StockError {
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
