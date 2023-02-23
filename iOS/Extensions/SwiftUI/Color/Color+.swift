//
//  Color+.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2023/01/07
//
//

import SwiftUI

extension Color {
    init(_ hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: Standard content background colors
extension Color {
    static let systemBackground = Color(uiColor: .systemBackground)
    static let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
    static let tertiarySystemBackground = Color(uiColor: .tertiarySystemBackground)
}

// MARK: Grouped content background colors
extension Color {
    static let systemGroupedBackground = Color(uiColor: .systemGroupedBackground)
    static let secondarySystemGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let tertiarySystemGroupedBackground = Color(uiColor: .tertiarySystemGroupedBackground)
    
}

// MARK: Separator colors
extension Color {
    static let separator = Color(uiColor: .separator)
    static let opaqueSeparator = Color(uiColor: .opaqueSeparator)
}

// MARK: Tint color
extension Color {
    static let tintColor = Color(uiColor: .tintColor)
}

// MARK: Text colors
extension Color {
    static let placeholderText = Color(uiColor: .placeholderText)
}

// MARK: Label colors
extension Color {
    static let label = Color(uiColor: .label)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)
    static let tertiaryLabel = Color(uiColor: .tertiaryLabel)
}

// MARK: Link color
extension Color {
    static let link = Color(uiColor: .link)
}

// MARK: Adaptable gray colors
extension Color {
    static let systemGray = Color(uiColor: .systemGray)
    static let systemGray2 = Color(uiColor: .systemGray2)
    static let systemGray3 = Color(uiColor: .systemGray3)
    static let systemGray4 = Color(uiColor: .systemGray4)
    static let systemGray5 = Color(uiColor: .systemGray5)
    static let systemGray6 = Color(uiColor: .systemGray6)
}

// MARK: Fixed colors
extension Color {
    static let fixedBlack = Color(uiColor: UIColor(white: 0.0, alpha: 1.0))
    static let fixedDarkGray = Color(uiColor: UIColor(white: 0.33, alpha: 1.0))
    static let fixedLightGray = Color(uiColor: UIColor(white: 0.67, alpha: 1.0))
    static let fixedWhite = Color(uiColor: UIColor(white: 1.0, alpha: 1.0))
    static let fixedGray = Color(uiColor: UIColor(white: 0.5, alpha: 1.0))
    static let fixedRed = Color(uiColor: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
    static let fixedGreen = Color(uiColor: UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0))
    static let fixedBlue = Color(uiColor: UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0))
    static let fixedCyan = Color(uiColor: UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0))
    static let fixedYellow = Color(uiColor: UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0))
    static let fixedMagenta = Color(uiColor: UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0))
    static let fixedOrange = Color(uiColor: UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0))
    static let fixedPurple = Color(uiColor: UIColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0))
    static let fixedBrown = Color(uiColor: UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0))
}
