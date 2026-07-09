//
//  IDPhotoBackgroundColor.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreGraphics
import CoreImage

/// 証明写真の背景色。
///
/// UI フレームワークに依存させないため、コア層では数値 (成分 + 色空間) のみを保持する。
/// アプリ側のプリセット (青・グレー・白・茶) は extension で提供される。
struct IDPhotoBackgroundColor: Identifiable, Sendable {

    enum RGBColorSpace: String, Codable, Sendable {
        case sRGB
        case displayP3

        var cgColorSpace: CGColorSpace? {
            switch self {

            case .sRGB:
                return CGColorSpace(name: CGColorSpace.sRGB)

            case .displayP3:
                return CGColorSpace(name: CGColorSpace.displayP3)
            }
        }
    }

    enum Fill: Sendable {

        /// 背景合成なし (元画像の背景のまま)
        case original

        case solid(red: Double, green: Double, blue: Double, alpha: Double, colorSpace: RGBColorSpace)
    }

    let fill: Fill

    init(fill: Fill) {
        self.fill = fill
    }

    /// 背景合成なし (元画像の背景のまま)
    static let original: IDPhotoBackgroundColor = .init(fill: .original)

    /// 同一色判定・永続化後の照合に使える安定 ID (成分から導出される)
    var id: String {
        switch fill {

        case .original:
            return "original"

        case .solid(let red, let green, let blue, let alpha, let colorSpace):
            let roundedComponents: [String] = [red, green, blue, alpha].map { String(format: "%.5f", $0) }

            return "solid:\(roundedComponents.joined(separator: "_")):\(colorSpace.rawValue)"
        }
    }

    /// 背景合成に使用する CIColor。`.original` の場合は nil
    var ciColor: CIColor? {
        guard case .solid(let red, let green, let blue, let alpha, let colorSpace) = fill else { return nil }

        guard let cgColorSpace = colorSpace.cgColorSpace else { return nil }

        return CIColor(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha,
            colorSpace: cgColorSpace
        )
    }
}

extension IDPhotoBackgroundColor: Equatable {
    static func == (lhs: IDPhotoBackgroundColor, rhs: IDPhotoBackgroundColor) -> Bool {
        return lhs.id == rhs.id
    }
}

extension IDPhotoBackgroundColor {

    /// 色空間の違いを吸収した同一色判定 (Display P3 へ変換して成分を比較する)。
    /// 永続化された成分からプリセットを復元するときに使用する
    func isSameColor(as other: IDPhotoBackgroundColor) -> Bool {
        if self == other { return true }

        guard
            let selfComponents: [CGFloat] = self.displayP3Components(),
            let otherComponents: [CGFloat] = other.displayP3Components(),
            selfComponents.count == otherComponents.count
        else { return false }

        let COMPONENT_TOLERANCE: CGFloat = 0.001

        let componentPairs: Zip2Sequence<[CGFloat], [CGFloat]> = zip(selfComponents, otherComponents)

        return componentPairs.allSatisfy { abs($0 - $1) <= COMPONENT_TOLERANCE }
    }

    private func displayP3Components() -> [CGFloat]? {
        guard case .solid(let red, let green, let blue, let alpha, let colorSpace) = fill else { return nil }

        guard
            let cgColorSpace = colorSpace.cgColorSpace,
            let displayP3ColorSpace = RGBColorSpace.displayP3.cgColorSpace
        else { return nil }

        let cgColor: CGColor? = .init(
            colorSpace: cgColorSpace,
            components: [red, green, blue, alpha]
        )

        let convertedCGColor: CGColor? = cgColor?.converted(
            to: displayP3ColorSpace,
            intent: .defaultIntent,
            options: nil
        )

        return convertedCGColor?.components
    }
}
