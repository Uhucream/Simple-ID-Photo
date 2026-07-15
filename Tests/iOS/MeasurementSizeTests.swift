//
//  MeasurementSizeTests.swift
//  Simple ID Photo Tests
//
//  Created by TakashiUshikoshi on 2026/07/10
//
//

import Testing
import Foundation
@testable import SimpleIDPhoto

@Suite("MeasurementSize (物理寸法)")
struct MeasurementSizeTests {

    private func size(width: Double, height: Double) -> MeasurementSize {
        return .init(width: .millimeters(width), height: .millimeters(height))
    }

    @Test("高さが異なる場合は高さの昇順で比較する")
    func comparesByHeightFirst() {
        //  25×25 (h25) < 24×30 (h30) : 高さが小さい方が先
        #expect(size(width: 25, height: 25) < size(width: 24, height: 30))

        //  50×50 (h50) < 40×60 (h60)
        #expect(size(width: 50, height: 50) < size(width: 40, height: 60))
    }

    @Test("高さが同じ場合は横幅の昇順で比較する")
    func comparesByWidthWhenHeightIsEqual() {
        #expect(size(width: 24, height: 30) < size(width: 25, height: 30))
        #expect(size(width: 40, height: 60) < size(width: 45, height: 60))
    }

    @Test("単位が異なっても正規化して比較する")
    func comparesAcrossUnits() {
        let threeCentimeters: MeasurementSize = .init(width: .millimeters(24), height: .centimeters(3))
        let thirtyMillimeters: MeasurementSize = .init(width: .millimeters(25), height: .millimeters(30))

        //  高さは 3cm == 30mm で等しいので横幅で比較され 24 < 25
        #expect(threeCentimeters < thirtyMillimeters)
    }

    @Test("配列を sorted() すると高さ→横幅の昇順に並ぶ")
    func sortsAscendingByHeightThenWidth() {
        let shuffledSizes: [MeasurementSize] = [
            size(width: 50, height: 70),
            size(width: 30, height: 40),
            size(width: 25, height: 25),
            size(width: 45, height: 60),
            size(width: 24, height: 30),
            size(width: 40, height: 60),
            size(width: 30, height: 30),
            size(width: 25, height: 30)
        ]

        let expectedSizes: [MeasurementSize] = [
            size(width: 25, height: 25),
            size(width: 24, height: 30),
            size(width: 25, height: 30),
            size(width: 30, height: 30),
            size(width: 30, height: 40),
            size(width: 40, height: 60),
            size(width: 45, height: 60),
            size(width: 50, height: 70)
        ]

        #expect(shuffledSizes.sorted() == expectedSizes)
    }
}
