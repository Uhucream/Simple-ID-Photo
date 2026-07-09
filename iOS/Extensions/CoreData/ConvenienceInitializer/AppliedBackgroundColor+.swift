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
        backgroundColor: IDPhotoBackgroundColor,
        createdIDPhoto: CreatedIDPhoto? = nil
    ) {
        self.init(context: context)

        self.id = id

        switch backgroundColor.fill {

        case .original:
            //  「背景色なし」は alpha 0 で表現する (旧実装の .clear と同じ)
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

    /// 保存された成分から背景色を復元する。
    /// プリセットと同一色の場合は該当プリセットが返る
    func parseToIDPhotoBackgroundColor() -> IDPhotoBackgroundColor {
        return .fromStoredComponents(
            red: self.red,
            green: self.green,
            blue: self.blue,
            alpha: self.alpha,
            colorSpaceRawValue: self.colorSpace
        )
    }
}
