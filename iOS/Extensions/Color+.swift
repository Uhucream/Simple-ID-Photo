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
    static let fixedBlack = Color(uiColor: .black)
    static let fixedDarkGray = Color(uiColor: .darkGray)
    static let fixedLightGray = Color(uiColor: .lightGray)
    static let fixedWhite = Color(uiColor: .white)
    static let fixedGray = Color(uiColor: .gray)
    static let fixedRed = Color(uiColor: .red)
    static let fixedGreen = Color(uiColor: .green)
    static let fixedBlue = Color(uiColor: .blue)
    static let fixedCyan = Color(uiColor: .cyan)
    static let fixedYellow = Color(uiColor: .yellow)
    static let fixedMagenta = Color(uiColor: .magenta)
    static let fixedOrange = Color(uiColor: .orange)
    static let fixedPurple = Color(uiColor: .purple)
    static let fixedBrown = Color(uiColor: .brown)
    static let fixedClear = Color(uiColor: .clear)
}
