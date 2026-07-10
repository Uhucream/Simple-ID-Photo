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

        switch self.sizeVariant {

        case 0:
            return OriginalSizeSpecification.original.id

        case 1:
            return JapanIDPhotoSize.reservedPassportSpecificationID

        default:
            return JapanIDPhotoSize(legacySizeVariantRawValue: self.sizeVariant)?.id
        }
    }

    /// 保存済みの仕様書 ID から復元したサイズ仕様書。
    /// 廃止されたサイズや未実装のパスポート規格は復元できないため nil
    var resolvedSizeSpecification: (any IDPhotoSizeSpecification)? {
        guard let resolvedID = self.resolvedSizeSpecificationID else { return nil }

        if resolvedID == OriginalSizeSpecification.original.id {
            return OriginalSizeSpecification.original
        }

        return JapanIDPhotoSize(rawValue: resolvedID)
    }

    /// 表示用ラベル。
    /// 仕様書 ID から解決できない場合 (廃止サイズ) は保存済みの mm 実寸にフォールバックする
    var sizeLabel: AppliedIDPhotoSizeLabel {
        let resolvedID: String? = self.resolvedSizeSpecificationID

        if resolvedID == OriginalSizeSpecification.original.id {
            return .original
        }

        if resolvedID == JapanIDPhotoSize.reservedPassportSpecificationID {
            return .passport
        }

        if
            let resolvedID = resolvedID,
            let japanIDPhotoSize = JapanIDPhotoSize(rawValue: resolvedID),
            let millimeterSize = japanIDPhotoSize.millimeterSize
        {
            return .millimeters(
                width: millimeterSize.width.converted(to: .millimeters).value,
                height: millimeterSize.height.converted(to: .millimeters).value
            )
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
