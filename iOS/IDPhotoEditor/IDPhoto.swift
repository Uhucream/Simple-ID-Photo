//
//  IDPhoto.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreImage

/// IDPhotoEditor の操作結果として返される証明写真
struct IDPhoto {

    let ciImage: CIImage

    /// 適用済みの背景色。一度も背景合成されていない場合は nil
    let appliedBackgroundColor: IDPhotoBackgroundColor?

    /// 適用されたクロップ矩形 (元画像の CoreImage 座標系)。クロップされていない場合は nil
    let appliedCroppingRect: CGRect?
}
