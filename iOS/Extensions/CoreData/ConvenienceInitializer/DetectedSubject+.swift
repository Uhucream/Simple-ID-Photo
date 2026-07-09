//
//  DetectedSubject+.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import CoreData
import CoreGraphics

extension DetectedSubject {

    /// 検出アルゴリズムの版数。
    /// 検出ロジックを変更した場合 (iOS 18 の新 Vision API への移行など) はこの値を上げることで、
    /// 古い検出結果を無効化して再検出させる
    static let CURRENT_DETECTION_VERSION: Int16 = 1

    convenience init(
        on context: NSManagedObjectContext,
        id: UUID = .init(),
        subject: IDPhotoSubject,
        sourcePhoto: SourcePhoto? = nil
    ) {
        self.init(context: context)

        self.id = id

        self.imageWidth = subject.imageExtent.width
        self.imageHeight = subject.imageExtent.height

        self.faceRectX = subject.faceWithHairRect.origin.x
        self.faceRectY = subject.faceWithHairRect.origin.y
        self.faceRectWidth = subject.faceWithHairRect.width
        self.faceRectHeight = subject.faceWithHairRect.height

        self.crownY = subject.crownY
        self.chinY = subject.chinY
        self.eyeCenterY = subject.eyeCenterY.map { NSNumber(value: Double($0)) }

        self.detectionVersion = DetectedSubject.CURRENT_DETECTION_VERSION

        self.sourcePhoto = sourcePhoto
    }

    /// 保存された検出結果を IDPhotoSubject に復元する。
    /// 検出アルゴリズムの版数が現在と異なる場合は nil (再検出させる)
    func parseToIDPhotoSubject() -> IDPhotoSubject? {
        guard self.detectionVersion == DetectedSubject.CURRENT_DETECTION_VERSION else { return nil }

        guard self.imageWidth > .zero, self.imageHeight > .zero else { return nil }

        let imageExtent: CGRect = .init(
            origin: .zero,
            size: CGSize(width: self.imageWidth, height: self.imageHeight)
        )

        let faceWithHairRect: CGRect = .init(
            x: self.faceRectX,
            y: self.faceRectY,
            width: self.faceRectWidth,
            height: self.faceRectHeight
        )

        return IDPhotoSubject(
            imageExtent: imageExtent,
            faceWithHairRect: faceWithHairRect,
            crownY: self.crownY,
            chinY: self.chinY,
            eyeCenterY: self.eyeCenterY.map { CGFloat($0.doubleValue) }
        )
    }
}
