//
//  JapanIDPhotoSize.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreGraphics

/// 日本の証明写真の規格サイズ
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

    /// 長型枠 (3.0 × 2.5 cm)
    ///
    /// 正方・小 (square25) のベースになるサイズ
    case w25xh30 = "jp.w25h30"

    /// 一般・履歴書 (4.0 × 3.0 cm)
    case w30xh40 = "jp.w30h40"

    /// 4.5 × 3.5 cm (パスポート規格外・標準の写り方)
    ///
    /// - Important: 同寸法のパスポート規格 (規格の写り方) と誤認したユーザーが
    ///   パスポート申請に使ってしまうのを防ぐため、パスポートサイズ対応が完了するまで
    ///   ピッカーには表示しないこと (表示可否は ViewContainer 側で制御する)
    case w35xh45 = "jp.w35h45"

    /// 正方・小 (2.5 × 2.5 cm)
    ///
    /// 長型枠 (w25xh30) の下部を 0.5 cm カットして作る
    case square25 = "jp.square25"

    /// 正方・中 (3.0 × 3.0 cm)
    ///
    /// 一般・履歴書 (w30xh40) の下部を 1.0 cm カットして作る
    case square30 = "jp.square30"

    /// 大型 (6.0 × 4.0 cm)
    ///
    /// 大型ベース (w50xh70) の下部を 1.0 cm、左右を各 0.5 cm カットして作る
    case w40xh60 = "jp.w40h60"

    /// 大型 (6.0 × 4.5 cm)
    ///
    /// 大型ベース (w50xh70) の下部を 1.0 cm、左右を各 0.25 cm カットして作る
    case w45xh60 = "jp.w45h60"

    /// 大型ベース (7.0 × 5.0 cm)
    ///
    /// 大型 2種 (w40xh60 / w45xh60) のベースになるサイズ
    case w50xh70 = "jp.w50h70"
}

extension JapanIDPhotoSize: CaseIterable, Identifiable {}

extension JapanIDPhotoSize: IDPhotoSizeSpecification {

    var id: String {
        return self.rawValue
    }

    var millimeterSize: MeasurementSize? {
        return self.specification.millimeterSize
    }

    var requiresSubjectDetection: Bool {
        return self.specification.requiresSubjectDetection
    }

    func croppingRect(for subject: IDPhotoSubject) throws -> CGRect {
        return try self.specification.croppingRect(for: subject)
    }
}

extension JapanIDPhotoSize {

    //  標準の写り方の顔占有率 (顔の高さ ÷ 写真の高さ)。
    //  根拠のある値ではなく暫定値 (適正値は要調査。変更する場合はこの定数を書き換えるだけでよい)
    private static let provisionalFaceHeightRatio: Double = 60 / 100

    //  頭頂から写真上端までの余白 (暫定値)
    private static let provisionalMillimeterCrownMargin: Measurement<UnitLength> = .millimeters(4)

    //  標準の写り方の仕様書。
    //  ベースになるサイズ (w25xh30 / w30xh40 / w50xh70) は自身の specification と
    //  派生サイズの baseSize の両方から参照されるため、定義を1箇所にまとめている
    private static let w24xh30Standard: FaceOccupancyIDPhotoSizeSpecification = standard(millimeterWidth: 24, millimeterHeight: 30)
    private static let w25xh30Standard: FaceOccupancyIDPhotoSizeSpecification = standard(millimeterWidth: 25, millimeterHeight: 30)
    private static let w30xh40Standard: FaceOccupancyIDPhotoSizeSpecification = standard(millimeterWidth: 30, millimeterHeight: 40)
    private static let w35xh45Standard: FaceOccupancyIDPhotoSizeSpecification = standard(millimeterWidth: 35, millimeterHeight: 45)
    private static let w50xh70Standard: FaceOccupancyIDPhotoSizeSpecification = standard(millimeterWidth: 50, millimeterHeight: 70)

    //  実体の仕様書。処理の分岐ではなく、case ごとの寸法データの選択
    private var specification: any IDPhotoSizeSpecification {
        switch self {

        case .w24xh30:
            return Self.w24xh30Standard

        case .w25xh30:
            return Self.w25xh30Standard

        case .w30xh40:
            return Self.w30xh40Standard

        case .w35xh45:
            return Self.w35xh45Standard

        case .w50xh70:
            return Self.w50xh70Standard

        case .square25:
            return EdgeCutIDPhotoSizeSpecification(
                id: self.rawValue,
                baseSize: Self.w25xh30Standard,
                millimeterBottomCut: .millimeters(5),
                millimeterHorizontalCutPerSide: .zero
            )

        case .square30:
            return EdgeCutIDPhotoSizeSpecification(
                id: self.rawValue,
                baseSize: Self.w30xh40Standard,
                millimeterBottomCut: .millimeters(10),
                millimeterHorizontalCutPerSide: .zero
            )

        case .w40xh60:
            return EdgeCutIDPhotoSizeSpecification(
                id: self.rawValue,
                baseSize: Self.w50xh70Standard,
                millimeterBottomCut: .millimeters(10),
                millimeterHorizontalCutPerSide: .millimeters(5)
            )

        case .w45xh60:
            return EdgeCutIDPhotoSizeSpecification(
                id: self.rawValue,
                baseSize: Self.w50xh70Standard,
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

    /// パスポート規格 (4.5 × 3.5 cm) の予約 ID
    ///
    /// 仕様書の実装はパスポートサイズ対応 (roadmap 5・別PR) で行うため、現時点では ID のみ予約している
    static let reservedPassportSpecificationID: String = "jp.passport"

    /// 旧 `IDPhotoSizeVariant` (enum の rawValue) からの変換
    ///
    /// 廃止されたサイズ (custom / w40_h50 / w40_h55 / w50_h50) は nil を返す。
    /// original (0) と passport (1) は本 enum の範囲外なので、呼び出し側で個別に扱う
    init?(legacySizeVariantRawValue: Int32) {
        switch legacySizeVariantRawValue {

        case 3:
            self = .w24xh30

        case 4:
            self = .w25xh30

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
