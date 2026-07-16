//
//  IDPhotoEditorError.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation

extension IDPhotoEditor {
    enum Error: LocalizedError {

        /// 人物を検出できなかった
        case personNotDetected

        /// 顔 (ランドマーク) を検出できなかった
        case faceNotDetected

        /// 指定されたサイズ仕様書のクロップ矩形を生成できなかった
        case croppingRegionUnsatisfiable

        /// 背景色を CIColor に変換できなかった
        case invalidBackgroundColor

        var errorDescription: String? {
            switch self {

            case .personNotDetected:
                return "人物を検出できませんでした"

            case .faceNotDetected:
                return "顔を検出できませんでした"

            case .croppingRegionUnsatisfiable:
                return "このサイズでの切り抜きができませんでした"

            case .invalidBackgroundColor:
                return "背景色を適用できませんでした"
            }
        }
    }
}
