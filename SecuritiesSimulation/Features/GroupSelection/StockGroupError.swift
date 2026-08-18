//
//  StockGroupError.swift
//  SecuritiesSimulation
//

import Foundation

/// Stock-group-domain errors surfaced to the GroupSelection feature.
/// Networking details (HTTP status codes, transport/decoding failures) are
/// translated into these cases by `StockGroupService` and must not leak any
/// further up.
enum StockGroupError: Error {
    case serviceUnavailable
    case unexpected
}
