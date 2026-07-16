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

    /// 仕様書 ID
    ///
    /// 未バックフィルのレコードは旧 sizeVariant からフォールバック解決する
    var resolvedSizeSpecificationID: String? {
        if let sizeSpecificationID = self.sizeSpecificationID {
            return sizeSpecificationID
        }

        switch self.sizeVariant {

        case 0:
            return OriginalSizeSpecification().id

        case 1:
            return JapanIDPhotoSize.reservedPassportSpecificationID

        default:
            return JapanIDPhotoSize(legacySizeVariantRawValue: self.sizeVariant)?.id
        }
    }

    /// 保存済みのレコードから復元したサイズ仕様書
    ///
    /// 現行の規格に無いサイズ (廃止サイズ) は保存済みの mm 実寸から復元する。
    /// mm も無い場合 (旧 custom レコードなど) のみ nil
    var resolvedSizeSpecification: (any IDPhotoSizeSpecification)? {
        if let resolvedID = self.resolvedSizeSpecificationID {
            if resolvedID == OriginalSizeSpecification().id {
                return .original
            }

            if let japanIDPhotoSize = JapanIDPhotoSize(rawValue: resolvedID) {
                return japanIDPhotoSize
            }
        }

        if self.millimetersWidth > .zero, self.millimetersHeight > .zero {
            return DiscontinuedIDPhotoSize(
                millimeterWidth: self.millimetersWidth,
                millimeterHeight: self.millimetersHeight
            )
        }

        return nil
    }

    /// 表示用ラベル
    ///
    /// 仕様書 ID から解決できない場合 (廃止サイズ) は保存済みの mm 実寸にフォールバックする
    var sizeLabel: AppliedIDPhotoSizeLabel {
        let resolvedID: String? = self.resolvedSizeSpecificationID

        if resolvedID == OriginalSizeSpecification().id {
            return .original
        }

        if resolvedID == JapanIDPhotoSize.reservedPassportSpecificationID {
            return .passport
        }

        if
            let resolvedID = resolvedID,
            let japanIDPhotoSize = JapanIDPhotoSize(rawValue: resolvedID)
        {
            let millimeterSize: MeasurementSize = japanIDPhotoSize.millimeterSize

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

