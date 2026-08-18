//
//  StockGroupService.swift
//  SecuritiesSimulation
//

import Foundation

protocol StockGroupServicing {
    func fetchStockGroups() async throws -> [StockGroup]
    func createStockGroup(name: String, stockCode: String) async throws -> StockGroup
}

final class StockGroupService: StockGroupServicing {

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchStockGroups() async throws -> [StockGroup] {
        do {
            return try await apiClient.get(path: "stock-groups")
        } catch let error as APIError {
            throw Self.stockGroupError(for: error)
        } catch {
            throw StockGroupError.unexpected
        }
    }

    func createStockGroup(name: String, stockCode: String) async throws -> StockGroup {
        do {
            let request = CreateStockGroupRequest(name: name, stockCode: stockCode)
            return try await apiClient.post(path: "stock-groups", body: request)
        } catch let error as APIError {
            throw Self.stockGroupError(for: error)
        } catch {
            throw StockGroupError.unexpected
        }
    }

    private static func stockGroupError(for error: APIError) -> StockGroupError {
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
