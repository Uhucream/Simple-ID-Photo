//
//  IDPhotoSubject.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreGraphics

/// 被写体 (証明写真の対象人物) の検出結果
///
/// すべての座標は CoreImage 座標系 (原点は左下、単位は px、元画像の extent 基準)。
struct IDPhotoSubject: Codable, Equatable, Sendable {

    /// 元画像の extent
    let imageExtent: CGRect

    /// 髪を含む顔の矩形
    ///
    /// 幅は顔の boundingBox の幅、上端は crownY、下端は chinY
    let faceWithHairRect: CGRect

    /// 頭頂の Y 座標
    ///
    /// 人物輪郭の boundingBox の上端
    let crownY: CGFloat

    /// 顎先端の Y 座標
    ///
    /// faceContour ランドマークの最下点
    let chinY: CGFloat

    /// 両瞳の中心の Y 座標
    ///
    /// 瞳のランドマークが検出できなかった場合は nil
    let eyeCenterY: CGFloat?
}
