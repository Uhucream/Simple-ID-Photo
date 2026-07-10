//
//  JapanIDPhotoSize.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreGraphics

/// 日本の証明写真の規格サイズ。
///
/// 出典: DNP フォトイメージング「証明写真サイズ一覧」(2023年5月時点)。
/// 詳細は `.claude/docs/photo_size_spec.md` を参照。
/// 他リージョンの規格サイズを追加する場合は、同様の専用型を新設する。
///
/// rawValue がそのまま永続化 ID (`AppliedIDPhotoSize.sizeSpecificationID`) になる。
/// 保存済み ID からの復元は `JapanIDPhotoSize(rawValue:)`。
enum JapanIDPhotoSize: String {

    /// 運転免許 (3.0 × 2.4 cm)
    case w24xh30 = "jp.w24h30"

    /// 一般・履歴書 (4.0 × 3.0 cm)
    case w30xh40 = "jp.w30h40"

    /// 4.5 × 3.5 cm (パスポート規格外・標準の写り方)。
    ///
    /// - Important: 同寸法のパスポート規格 (規格の写り方) と誤認したユーザーが
    ///   パスポート申請に使ってしまうのを防ぐため、パスポートサイズ対応が完了するまで
    ///   ピッカーには表示しない (表示可否は ViewContainer 側で制御する)
    case w35xh45 = "jp.w35h45"

    /// 正方・小 (2.5 × 2.5 cm)。長型枠 3.0 × 2.5 の下部を 0.5 cm カットして作る
    case square25 = "jp.square25"

    /// 正方・中 (3.0 × 3.0 cm)。4.0 × 3.0 の下部を 1.0 cm カットして作る
    case square30 = "jp.square30"

    /// 大型 (6.0 × 4.0 cm)。7.0 × 5.0 の下部を 1.0 cm、左右を各 0.5 cm カットして作る
    case w40xh60 = "jp.w40h60"

    /// 大型 (6.0 × 4.5 cm)。7.0 × 5.0 の下部を 1.0 cm、左右を各 0.25 cm カットして作る
    case w45xh60 = "jp.w45h60"
}

extension JapanIDPhotoSize: CaseIterable, Identifiable {}

extension JapanIDPhotoSize: IDPhotoSizeSpecification {

    var id: String {
        return self.rawValue
    }

    var millimeterSize: MeasurementSize? {
        return self.specification.millimeterSize
    }

    func croppingRect(for subject: IDPhotoSubject) throws -> CGRect {
        return try self.specification.croppingRect(for: subject)
    }
}

extension JapanIDPhotoSize {

    /// 標準の写り方の顔占有率 (顔の高さ ÷ 写真の高さ)。
    /// 根拠のある値ではなく暫定値 (適正値は要調査。変更する場合はこの定数を書き換えるだけでよい)
    private static let provisionalFaceHeightRatio: Double = 60 / 100

    /// 頭頂から写真上端までの余白 (暫定値)
    private static let provisionalMillimeterCrownMargin: Measurement<UnitLength> = .millimeters(4)

    //  実体の仕様書。処理の分岐ではなく、case ごとの寸法データの選択
    private var specification: any IDPhotoSizeSpecification {
        switch self {

        case .w24xh30:
            return Self.standard(millimeterWidth: 24, millimeterHeight: 30)

        case .w30xh40:
            return Self.standard(millimeterWidth: 30, millimeterHeight: 40)

        case .w35xh45:
            return Self.standard(millimeterWidth: 35, millimeterHeight: 45)

        case .square25:
            return EdgeCutIDPhotoSizeSpecification(
                id: self.rawValue,
                baseSize: Self.standard(millimeterWidth: 25, millimeterHeight: 30),
                millimeterBottomCut: .millimeters(5),
                millimeterHorizontalCutPerSide: .zero
            )

        case .square30:
            return EdgeCutIDPhotoSizeSpecification(
                id: self.rawValue,
                baseSize: Self.standard(millimeterWidth: 30, millimeterHeight: 40),
                millimeterBottomCut: .millimeters(10),
                millimeterHorizontalCutPerSide: .zero
            )

        case .w40xh60:
            return EdgeCutIDPhotoSizeSpecification(
                id: self.rawValue,
                baseSize: Self.standard(millimeterWidth: 50, millimeterHeight: 70),
                millimeterBottomCut: .millimeters(10),
                millimeterHorizontalCutPerSide: .millimeters(5)
            )

        case .w45xh60:
            return EdgeCutIDPhotoSizeSpecification(
                id: self.rawValue,
                baseSize: Self.standard(millimeterWidth: 50, millimeterHeight: 70),
                millimeterBottomCut: .millimeters(10),
                millimeterHorizontalCutPerSide: .millimeters(2.5)
            )
        }
    }

    private static func standard(
        millimeterWidth: Double,
        millimeterHeight: Double
    ) -> FaceOccupancyIDPhotoSizeSpecification {

        //  外向きの ID は enum の rawValue なので、内部の仕様書には ID を持たせない
        return FaceOccupancyIDPhotoSizeSpecification(
            id: "",
            dimensions: MeasurementSize(
                width: .millimeters(millimeterWidth),
                height: .millimeters(millimeterHeight)
            ),
            millimeterFaceHeight: .millimeters(millimeterHeight * provisionalFaceHeightRatio),
            millimeterCrownMargin: provisionalMillimeterCrownMargin
        )
    }
}

extension JapanIDPhotoSize {

    /// パスポート規格 (4.5 × 3.5 cm) の予約 ID。
    ///
    /// 仕様書の実装はパスポートサイズ対応 (roadmap 5・別PR) で行うため、現時点では ID のみ予約している。
    /// v4 レコードのバックフィルと表示ラベルの解決に使用する
    static let reservedPassportSpecificationID: String = "jp.passport"

    /// 旧 `IDPhotoSizeVariant` (enum の rawValue) からの変換 (Core Data v4 → v5 バックフィル用)。
    ///
    /// 廃止されたサイズ (custom / w25_h30 / w40_h50 / w40_h55 / w50_h50) は nil を返し、
    /// 保存済みの mm 実寸で表示される。
    /// original (0) と passport (1) は本 enum の範囲外なので、呼び出し側で個別に扱う
    init?(legacySizeVariantRawValue: Int32) {
        switch legacySizeVariantRawValue {

        case 3:
            self = .w24xh30

        case 5:
            self = .square30

        case 6:
            self = .w30xh40

        case 7:
            self = .w35xh45

        case 10:
            self = .w40xh60

        case 11:
            self = .w45xh60

        default:
            return nil
        }
    }
}
