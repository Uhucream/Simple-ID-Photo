//
//  FaceOccupancyIDPhotoSizeTests.swift
//  Simple ID Photo Tests
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Testing
import CoreGraphics
import Foundation
@testable import SimpleIDPhoto

@Suite("FaceOccupancyIDPhotoSize (標準の写り方)")
struct FaceOccupancyIDPhotoSizeTests {

    /// 手計算しやすい値の被写体。
    /// 顔 (髪込み) は x: 1200, 下端 (顎): 2000, 上端 (頭頂): 2900, 幅: 600
    private let subject: IDPhotoSubject = .init(
        imageExtent: CGRect(x: 0, y: 0, width: 3000, height: 4000),
        faceWithHairRect: CGRect(x: 1200, y: 2000, width: 600, height: 900),
        crownY: 2900,
        chinY: 2000,
        eyeCenterY: 2450
    )

    @Test("既知の被写体から期待どおりのクロップ矩形が生成される (旧 generateCroppingRect と同じ数式)")
    func croppingRectMatchesLegacyFormula() throws {
        let specification: FaceOccupancyIDPhotoSize = .init(
            id: "test.w30h40",
            dimensions: MillimeterSize(width: 30, height: 40),
            millimeterFaceHeight: 24,
            millimeterCrownMargin: 4
        )

        let croppingRect: CGRect = try specification.croppingRect(for: subject)

        //  顔占有率 24/40 = 0.6 → 高さ = 900 / 0.6 = 1500
        //  幅 = 1500 × (30/40) = 1125
        //  頭上余白 = 1500 × (4/40) = 150
        //  originX = 1200 - (1125 - 600) / 2 = 937.5
        //  originY = (2900 + 150) - 1500 = 1550
        #expect(abs(croppingRect.origin.x - 937.5) < 0.0001)
        #expect(abs(croppingRect.origin.y - 1550) < 0.0001)
        #expect(abs(croppingRect.width - 1125) < 0.0001)
        #expect(abs(croppingRect.height - 1500) < 0.0001)
    }

    @Test("顔矩形が .null の場合は throw する")
    func throwsWhenFaceRectIsNull() {
        let specification: FaceOccupancyIDPhotoSize = .init(
            id: "test.w30h40",
            dimensions: MillimeterSize(width: 30, height: 40),
            millimeterFaceHeight: 24,
            millimeterCrownMargin: 4
        )

        let subjectWithoutFace: IDPhotoSubject = .init(
            imageExtent: CGRect(x: 0, y: 0, width: 3000, height: 4000),
            faceWithHairRect: .null,
            crownY: .zero,
            chinY: .zero,
            eyeCenterY: nil
        )

        #expect(throws: IDPhotoEditorError.self) {
            try specification.croppingRect(for: subjectWithoutFace)
        }
    }
}

@Suite("IDPhotoSubject")
struct IDPhotoSubjectTests {

    @Test("Codable の往復で値が保たれる (eyeCenterY が nil の場合も含む)")
    func codableRoundTrip() throws {
        let subjects: [IDPhotoSubject] = [
            .init(
                imageExtent: CGRect(x: 0, y: 0, width: 3000, height: 4000),
                faceWithHairRect: CGRect(x: 1200, y: 2000, width: 600, height: 900),
                crownY: 2900,
                chinY: 2000,
                eyeCenterY: 2450
            ),
            .init(
                imageExtent: CGRect(x: 0, y: 0, width: 100, height: 100),
                faceWithHairRect: CGRect(x: 10, y: 10, width: 20, height: 30),
                crownY: 40,
                chinY: 10,
                eyeCenterY: nil
            )
        ]

        for subject in subjects {
            let encodedData: Data = try JSONEncoder().encode(subject)

            let decodedSubject: IDPhotoSubject = try JSONDecoder().decode(IDPhotoSubject.self, from: encodedData)

            #expect(decodedSubject == subject)
        }
    }
}
