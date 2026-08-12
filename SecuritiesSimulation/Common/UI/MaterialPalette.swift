//
//  MaterialPalette.swift
//  SecuritiesSimulation
//

import UIKit

/// Shared Material Design color tokens used across UIKit screens.
enum MaterialPalette {
    static let primary = UIColor(red: 0x0D / 255, green: 0x47 / 255, blue: 0xA1 / 255, alpha: 1) // Material Blue 900
    static let primaryVariant = UIColor(red: 0x1E / 255, green: 0x88 / 255, blue: 0xE5 / 255, alpha: 1) // Material Blue 600
    static let onPrimary = UIColor.white

    static let background = UIColor.systemBackground
    static let surface = UIColor.secondarySystemBackground

    static let error = UIColor(red: 0xB0 / 255, green: 0x00 / 255, blue: 0x20 / 255, alpha: 1)

    static let textPrimary = UIColor.label
    static let textSecondary = UIColor.secondaryLabel
    static let divider = UIColor.separator
}
