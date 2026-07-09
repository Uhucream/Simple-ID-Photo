//
//  AppliedIDPhotoSize+SizeLabel.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreData
import CoreGraphics

/// 保存済みレコードのサイズ表示用ラベル
enum AppliedIDPhotoSizeLabel: Equatable {

    case original

    case passport

    case millimeters(width: Double, height: Double)

    /// 廃止されたサイズなどで、仕様書 ID も mm 実寸も解決できない場合
    case unknown
}

extension AppliedIDPhotoSize {

    /// 仕様書 ID。未バックフィルのレコードは旧 sizeVariant からフォールバック解決する
    var resolvedSizeSpecificationID: String? {
        if let sizeSpecificationID = self.sizeSpecificationID {
            return sizeSpecificationID
        }

        return JapanIDPhotoSizes.sizeSpecificationID(fromLegacySizeVariantRawValue: self.sizeVariant)
    }

    /// 表示用ラベル。
    /// 仕様書 ID から解決できない場合 (廃止サイズ) は保存済みの mm 実寸にフォールバックする
    var sizeLabel: AppliedIDPhotoSizeLabel {
        let resolvedID: String? = self.resolvedSizeSpecificationID

        if resolvedID == JapanIDPhotoSizes.original.id {
            return .original
        }

        if resolvedID == JapanIDPhotoSizes.passportSizeSpecificationID {
            return .passport
        }

        if
            let specification = JapanIDPhotoSizes.specification(matching: resolvedID),
            let millimeterSize = specification.millimeterSize
        {
            return .millimeters(width: millimeterSize.width, height: millimeterSize.height)
        }

        if self.millimetersWidth > .zero, self.millimetersHeight > .zero {
            return .millimeters(width: self.millimetersWidth, height: self.millimetersHeight)
        }

        return .unknown
    }
}

extension AppliedIDPhotoSizeLabel {

    /// サムネイルのプレースホルダなどに使用するアスペクト比 (幅 ÷ 高さ)。解決できない場合は nil
    var aspectRatio: CGFloat? {
        guard case .millimeters(let width, let height) = self, height > .zero else { return nil }

        return width / height
    }
}
