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

    /// 検出アルゴリズムの版数
    ///
    /// 検出ロジックを変更した場合 (iOS 18 の新 Vision API への移行など) はこの値を上げることで、
    /// 古い検出結果を無効化して再検出させる
    static let currentDetectionVersion: Int16 = 1

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

        self.detectionVersion = DetectedSubject.currentDetectionVersion

        self.sourcePhoto = sourcePhoto
    }
}

extension IDPhotoSubject {

    /// 保存された検出結果から復元する
    ///
    /// 検出アルゴリズムの版数が現在と異なる場合は nil
    init?(_ detectedSubject: DetectedSubject) {
        guard detectedSubject.detectionVersion == DetectedSubject.currentDetectionVersion else { return nil }

        guard detectedSubject.imageWidth > .zero, detectedSubject.imageHeight > .zero else { return nil }

        let imageExtent: CGRect = .init(
            origin: .zero,
            size: CGSize(width: detectedSubject.imageWidth, height: detectedSubject.imageHeight)
        )

        let faceWithHairRect: CGRect = .init(
            x: detectedSubject.faceRectX,
            y: detectedSubject.faceRectY,
            width: detectedSubject.faceRectWidth,
            height: detectedSubject.faceRectHeight
        )

        self.init(
            imageExtent: imageExtent,
            faceWithHairRect: faceWithHairRect,
            crownY: detectedSubject.crownY,
            chinY: detectedSubject.chinY,
            eyeCenterY: detectedSubject.eyeCenterY.map { CGFloat($0.doubleValue) }
        )
    }
}
