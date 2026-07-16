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
/// 被写体の検出結果からクロップ矩形を生成する。
protocol IDPhotoSizeSpecification: Identifiable, Sendable {

    /// 仕様書の種類を一意に表す識別子
    var id: String { get }

    /// 写真の物理寸法
    var millimeterSize: MeasurementSize { get }

    /// クロップ矩形の生成に被写体の検出結果を必要とするか
    ///
    /// false の場合、`croppingRect(for:)` の subject には検出結果ではなく画像全体の情報のみが渡される
    var requiresSubjectDetection: Bool { get }

    /// subject から、元画像の CoreImage 座標系 (原点込み) のクロップ矩形を生成する
    ///
    /// 生成できない場合は throw する
    func croppingRect(for subject: IDPhotoSubject) throws -> CGRect
}
