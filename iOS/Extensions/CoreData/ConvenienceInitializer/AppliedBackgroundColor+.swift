//
//  AppliedBackgroundColor+.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2023/03/01
//
//

import CoreData

extension AppliedBackgroundColor {
    convenience init(
        on context: NSManagedObjectContext,
        id: UUID = .init(),
        color: IDPhotoBackgroundColor,
        createdIDPhoto: CreatedIDPhoto? = nil
    ) {
        self.init(context: context)

        self.id = id

        switch color {

        case .clear:
            //  「背景色なし」は alpha 0 で表現する (旧実装の Color.clear と同じ)
            self.red = .zero
            self.green = .zero
            self.blue = .zero
            self.alpha = .zero
            self.colorSpace = nil

        case .solid(let red, let green, let blue, let alpha, let colorSpace):
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
            self.colorSpace = colorSpace.rawValue
        }

        self.createdIDPhoto = createdIDPhoto
    }

}

extension IDPhotoBackgroundColor {

    /// 保存されたレコードから復元する
    ///
    /// プリセットと同一色の場合は該当プリセットになる
    init(_ appliedBackgroundColor: AppliedBackgroundColor) {
        self.init(
            red: appliedBackgroundColor.red,
            green: appliedBackgroundColor.green,
            blue: appliedBackgroundColor.blue,
            alpha: appliedBackgroundColor.alpha,
            colorSpaceRawValue: appliedBackgroundColor.colorSpace
        )
    }
}
