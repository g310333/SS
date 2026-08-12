//
//  AppConfiguration.swift
//  SecuritiesSimulation
//

import Foundation

/// Environment-specific configuration. Debug and Release currently point at
/// the same local development API; this is the seam where they'd diverge.
enum AppConfiguration {
    static let apiBaseURL: URL = {
        #if DEBUG
        return URL(string: "http://127.0.0.1:8000/")!
        #else
        return URL(string: "http://127.0.0.1:8000/")!
        #endif
    }()
}
