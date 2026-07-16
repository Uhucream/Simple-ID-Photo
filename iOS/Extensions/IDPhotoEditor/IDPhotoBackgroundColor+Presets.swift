//
//  IDPhotoBackgroundColor+Presets.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import SwiftUI
import UIKit

extension IDPhotoBackgroundColor {
    /// SwiftUI の Color から背景色を生成する (カスタムカラー用)
    static func custom(_ color: Color) -> IDPhotoBackgroundColor {
        let cgColor: CGColor = color.cgColor ?? UIColor(color).cgColor

        let displayP3ColorSpace: CGColorSpace? = RGBColorSpace.displayP3.cgColorSpace

        guard let displayP3ColorSpace else {
            return .clear
        }

        //  色空間の違いによる成分の揺れをなくすため、Display P3 に正規化して保持する
        let convertedCGColor: CGColor? = cgColor.converted(
            to: displayP3ColorSpace,
            intent: .defaultIntent,
            options: nil
        )

        let components: [CGFloat]? = convertedCGColor?.components

        guard let components, components.count >= 4 else { return .clear }

        return .solid(
            red: Double(components[0]),
            green: Double(components[1]),
            blue: Double(components[2]),
            alpha: Double(components[3]),
            colorSpace: .displayP3
        )
    }
}

//  プリセット (asset catalog の色から生成)
extension IDPhotoBackgroundColor {
    static let blue: IDPhotoBackgroundColor = .custom(Color.idPhotoBackgroundColors.blue)
    static let gray: IDPhotoBackgroundColor = .custom(Color.idPhotoBackgroundColors.gray)
    static let white: IDPhotoBackgroundColor = .custom(Color.idPhotoBackgroundColors.white)
    static let brown: IDPhotoBackgroundColor = .custom(Color.idPhotoBackgroundColors.brown)
}

extension IDPhotoBackgroundColor {
    static let presets: [IDPhotoBackgroundColor] = [
        .blue,
        .gray,
        .white,
        .brown
    ]
}

//  SwiftUI 連携
extension IDPhotoBackgroundColor {
    /// UI に表示する色名ラベル
    var label: String {
        switch self {
        case .clear:
            return "背景色なし"
        case .blue:
            return "青"
        case .gray:
            return "グレー"
        case .white:
            return "白"
        case .brown:
            return "茶"
        default:
            return "カスタム"
        }
    }
}

//  永続化された成分からの復元
extension IDPhotoBackgroundColor {

    /// 保存された RGBA 成分から復元する
    ///
    /// プリセットと同一色 (色空間変換込みで比較) の場合は該当プリセットになる。
    /// alpha が 0 の場合は「背景色なし」(`.clear`) になる
    init(
        red: Double,
        green: Double,
        blue: Double,
        alpha: Double,
        colorSpaceRawValue: String?
    ) {
        guard alpha > .zero else {
            self = .clear

            return
        }

        let colorSpace: RGBColorSpace = colorSpaceRawValue.flatMap { RGBColorSpace(rawValue: $0) } ?? .sRGB

        let restoredBackgroundColor: IDPhotoBackgroundColor = .solid(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha,
            colorSpace: colorSpace
        )

        let matchedPreset: IDPhotoBackgroundColor? = IDPhotoBackgroundColor.presets.first { $0.isSameColor(as: restoredBackgroundColor) }

        self = matchedPreset ?? restoredBackgroundColor
    }
}
