//
//  IDPhotoBackgroundColorTests.swift
//  Simple ID Photo Tests
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Testing
@testable import SimpleIDPhoto

@Suite("IDPhotoBackgroundColor")
struct IDPhotoBackgroundColorTests {

    @Test("同じ成分からは同じ ID が導出され、Equatable が成立する")
    func idIsStableForSameComponents() {
        let firstColor: IDPhotoBackgroundColor = .solid(red: 0.5, green: 0.25, blue: 0.75, alpha: 1, colorSpace: .sRGB)
        let secondColor: IDPhotoBackgroundColor = .solid(red: 0.5, green: 0.25, blue: 0.75, alpha: 1, colorSpace: .sRGB)

        #expect(firstColor.id == secondColor.id)
        #expect(firstColor == secondColor)

        #expect(IDPhotoBackgroundColor.clear.id == "clear")
        #expect(firstColor != .clear)
    }

    @Test("色空間が違えば ID は別物になる (成分比較には isSameColor を使う)")
    func idDiffersAcrossColorSpaces() {
        let sRGBWhite: IDPhotoBackgroundColor = .solid(red: 1, green: 1, blue: 1, alpha: 1, colorSpace: .sRGB)
        let displayP3White: IDPhotoBackgroundColor = .solid(red: 1, green: 1, blue: 1, alpha: 1, colorSpace: .displayP3)

        #expect(sRGBWhite.id != displayP3White.id)

        //  白は sRGB でも Display P3 でも同じ色
        #expect(sRGBWhite.isSameColor(as: displayP3White))
    }

    @Test("保存された成分の alpha が 0 なら「背景色なし」として復元される (旧 Color.clear 相当)")
    func zeroAlphaRestoresAsClear() {
        let restoredColor: IDPhotoBackgroundColor = .init(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 0,
            colorSpaceRawValue: nil
        )

        #expect(restoredColor == .clear)
    }

    @Test("プリセットと同一色の保存成分はプリセットとして復元される")
    func storedPresetComponentsRestoreAsPreset() {
        guard case .solid(let red, let green, let blue, let alpha, let colorSpace) = IDPhotoBackgroundColor.blue else {
            Issue.record("プリセット blue が solid ではない")

            return
        }

        let restoredColor: IDPhotoBackgroundColor = .init(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha,
            colorSpaceRawValue: colorSpace.rawValue
        )

        #expect(restoredColor == .blue)
        #expect(restoredColor.label == "青")
    }

    @Test("プリセットのどれとも一致しない成分はカスタムとして復元される")
    func storedUnknownComponentsRestoreAsCustom() {
        let restoredColor: IDPhotoBackgroundColor = .init(
            red: 0.9,
            green: 0.1,
            blue: 0.1,
            alpha: 1,
            colorSpaceRawValue: "sRGB"
        )

        #expect(IDPhotoBackgroundColor.presets.contains(restoredColor) == false)
        #expect(restoredColor.label == "カスタム")
    }
}
