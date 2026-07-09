//
//  JapanIDPhotoSizes.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation

/// 日本向けの証明写真サイズ一覧。
///
/// 出典: DNP フォトイメージング「証明写真サイズ一覧」(2023年5月時点)。
/// 詳細は `.claude/docs/photo_size_spec.md` を参照。
/// 他リージョンの一覧を追加する場合は、同様の専用型を新設する。
enum JapanIDPhotoSizes {

    /// 標準の写り方の顔占有率 (顔の高さ ÷ 写真の高さ)。
    /// 根拠のある値ではなく暫定値 (適正値は要調査。変更する場合はこの定数を書き換えるだけでよい)
    private static let PROVISIONAL_FACE_HEIGHT_RATIO: Double = 60 / 100

    /// 頭頂から写真上端までの余白 (暫定値)
    private static let PROVISIONAL_MILLIMETER_CROWN_MARGIN: Double = 4

    private static func standardSize(
        id: String,
        millimeterWidth: Double,
        millimeterHeight: Double
    ) -> FaceOccupancyIDPhotoSize {

        return FaceOccupancyIDPhotoSize(
            id: id,
            dimensions: MillimeterSize(width: millimeterWidth, height: millimeterHeight),
            millimeterFaceHeight: millimeterHeight * PROVISIONAL_FACE_HEIGHT_RATIO,
            millimeterCrownMargin: PROVISIONAL_MILLIMETER_CROWN_MARGIN
        )
    }

    /// オリジナルサイズ (切り抜きなし)
    static let original: OriginalSizeSpecification = .init()

    /// 運転免許 (3.0 × 2.4 cm)
    static let w24h30: FaceOccupancyIDPhotoSize = standardSize(
        id: "jp.w24h30",
        millimeterWidth: 24,
        millimeterHeight: 30
    )

    /// 一般・履歴書 (4.0 × 3.0 cm)
    static let w30h40: FaceOccupancyIDPhotoSize = standardSize(
        id: "jp.w30h40",
        millimeterWidth: 30,
        millimeterHeight: 40
    )

    /// 4.5 × 3.5 cm (パスポート規格外・標準の写り方)。
    ///
    /// - Important: 同寸法のパスポート規格 (規格の写り方) と誤認したユーザーが
    ///   パスポート申請に使ってしまうのを防ぐため、パスポートサイズ対応が完了するまで
    ///   `pickerLineup` には含めない (定義のみ)
    static let w35h45: FaceOccupancyIDPhotoSize = standardSize(
        id: "jp.w35h45",
        millimeterWidth: 35,
        millimeterHeight: 45
    )

    /// 正方・小 (2.5 × 2.5 cm)。長型枠 3.0 × 2.5 の下部を 0.5 cm カットして作る
    static let square25: EdgeCutIDPhotoSize = .init(
        id: "jp.square25",
        baseSize: standardSize(id: "jp.square25.base", millimeterWidth: 25, millimeterHeight: 30),
        millimeterBottomCut: 5,
        millimeterHorizontalCutPerSide: 0
    )

    /// 正方・中 (3.0 × 3.0 cm)。4.0 × 3.0 の下部を 1.0 cm カットして作る
    static let square30: EdgeCutIDPhotoSize = .init(
        id: "jp.square30",
        baseSize: standardSize(id: "jp.square30.base", millimeterWidth: 30, millimeterHeight: 40),
        millimeterBottomCut: 10,
        millimeterHorizontalCutPerSide: 0
    )

    /// 大型 (6.0 × 4.0 cm)。7.0 × 5.0 の下部を 1.0 cm、左右を各 0.5 cm カットして作る
    static let w40h60: EdgeCutIDPhotoSize = .init(
        id: "jp.w40h60",
        baseSize: standardSize(id: "jp.w40h60.base", millimeterWidth: 50, millimeterHeight: 70),
        millimeterBottomCut: 10,
        millimeterHorizontalCutPerSide: 5
    )

    /// 大型 (6.0 × 4.5 cm)。7.0 × 5.0 の下部を 1.0 cm、左右を各 0.25 cm カットして作る
    static let w45h60: EdgeCutIDPhotoSize = .init(
        id: "jp.w45h60",
        baseSize: standardSize(id: "jp.w45h60.base", millimeterWidth: 50, millimeterHeight: 70),
        millimeterBottomCut: 10,
        millimeterHorizontalCutPerSide: 2.5
    )

    /// パスポート規格 (4.5 × 3.5 cm) の予約 ID。仕様書の実装はパスポートサイズ対応 (別PR) で行う
    static let passportSizeSpecificationID: String = "jp.passport"

    /// ピッカーに表示するサイズ一覧
    static let pickerLineup: [any IDPhotoSizeSpecification] = [
        original,
        w24h30,
        square25,
        square30,
        w30h40,
        w40h60,
        w45h60
    ]

    /// 永続化された ID から解決できるすべての仕様書 (ピッカー非表示のものを含む)
    static let allSpecifications: [any IDPhotoSizeSpecification] = pickerLineup + [w35h45]

    /// 永続化された ID から仕様書を復元する
    static func specification(matching sizeSpecificationID: String?) -> (any IDPhotoSizeSpecification)? {
        guard let sizeSpecificationID = sizeSpecificationID else { return nil }

        return allSpecifications.first { $0.id == sizeSpecificationID }
    }

    /// 旧 `IDPhotoSizeVariant` (enum の rawValue) から仕様書 ID へのマッピング。
    ///
    /// Core Data モデル v4 → v5 のバックフィルに使用する。
    /// 廃止されたサイズ (custom / w25_h30 / w40_h50 / w40_h55 / w50_h50) は nil を返し、
    /// 保存済みの mm 実寸で表示される。
    static func sizeSpecificationID(fromLegacySizeVariantRawValue rawValue: Int32) -> String? {
        switch rawValue {

        case 0:
            return original.id

        case 1:
            return passportSizeSpecificationID

        case 3:
            return w24h30.id

        case 5:
            return square30.id

        case 6:
            return w30h40.id

        case 7:
            return w35h45.id

        case 10:
            return w40h60.id

        case 11:
            return w45h60.id

        default:
            return nil
        }
    }
}
