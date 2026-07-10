//
//  IDPhotoSizeSpecification.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreGraphics

/// 証明写真の「サイズ仕様書」。
///
/// `IDPhotoEditor.cropped(to:)` に渡され、被写体の検出結果からクロップ矩形を生成する。
/// クロップ矩形の計算ロジックは各仕様書に閉じており、エディタ自身は計算を一切持たない。
protocol IDPhotoSizeSpecification: Identifiable, Sendable {

    /// 永続化に使用する安定 ID (例: "jp.w30h40", "original", "custom:<UUID>")
    var id: String { get }

    /// 表示・印刷に使用する物理寸法。オリジナルサイズ (切り抜きなし) の場合は nil
    var millimeterSize: MeasurementSize? { get }

    /// クロップ矩形の生成に被写体の検出結果を必要とするか。
    /// false の場合、`croppingRect(for:)` の subject には検出結果ではなく画像全体の情報のみが渡される
    var requiresSubjectDetection: Bool { get }

    /// subject から、元画像の CoreImage 座標系 (原点込み) のクロップ矩形を生成する。
    /// 生成できない場合は throw する (エディタはそのまま rethrow する)
    func croppingRect(for subject: IDPhotoSubject) throws -> CGRect
}

extension IDPhotoSizeSpecification {
    var requiresSubjectDetection: Bool {
        return true
    }
}
