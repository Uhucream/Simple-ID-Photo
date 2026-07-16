//
//  JapanIDPhotoSizeTests.swift
//  Simple ID Photo Tests
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Testing
@testable import SimpleIDPhoto

@Suite("JapanIDPhotoSize (日本の規格サイズ)")
struct JapanIDPhotoSizeTests {

    @Test("旧 IDPhotoSizeVariant の rawValue から変換できる")
    func legacySizeVariantMapping() {
        //  旧 enum の並び: original(0), passport(1), custom(2), w24_h30(3), w25_h30(4), w30_h30(5),
        //  w30_h40(6), w35_h45(7), w40_h50(8), w40_h55(9), w40_h60(10), w45_h60(11), w50_h50(12)
        #expect(JapanIDPhotoSize(legacySizeVariantRawValue: 3) == .w24xh30)
        #expect(JapanIDPhotoSize(legacySizeVariantRawValue: 4) == .w25xh30)
        #expect(JapanIDPhotoSize(legacySizeVariantRawValue: 5) == .square30)
        #expect(JapanIDPhotoSize(legacySizeVariantRawValue: 6) == .w30xh40)
        #expect(JapanIDPhotoSize(legacySizeVariantRawValue: 7) == .w35xh45)
        #expect(JapanIDPhotoSize(legacySizeVariantRawValue: 10) == .w40xh60)
        #expect(JapanIDPhotoSize(legacySizeVariantRawValue: 11) == .w45xh60)
    }

    @Test("廃止されたサイズと本 enum の範囲外 (original / passport) は nil を返す")
    func unresolvableLegacySizeVariantsMapToNil() {
        //  0 (original) と 1 (passport) は呼び出し側で個別に扱う
        //  2 / 8 / 9 / 12 は廃止されたサイズ (mm 実寸フォールバックに委ねる)
        let unresolvableRawValues: [Int32] = [0, 1, 2, 8, 9, 12]

        for rawValue in unresolvableRawValues {
            #expect(JapanIDPhotoSize(legacySizeVariantRawValue: rawValue) == nil)
        }
    }

    @Test("永続化 ID (rawValue) から復元できる")
    func restoresFromPersistedID() {
        #expect(JapanIDPhotoSize(rawValue: "jp.w30h40") == .w30xh40)
        #expect(JapanIDPhotoSize(rawValue: "jp.square25") == .square25)

        //  未知の ID (廃止サイズ・未実装のパスポート規格) は復元できない
        #expect(JapanIDPhotoSize(rawValue: "jp.passport") == nil)
        #expect(JapanIDPhotoSize(rawValue: "unknown") == nil)
    }

    @Test("派生サイズのカット後寸法が DNP 仕様と一致する")
    func derivedSizeDimensionsMatchSpecification() {
        #expect(JapanIDPhotoSize.square25.millimeterSize == MeasurementSize(width: .millimeters(25), height: .millimeters(25)))
        #expect(JapanIDPhotoSize.square30.millimeterSize == MeasurementSize(width: .millimeters(30), height: .millimeters(30)))
        #expect(JapanIDPhotoSize.w40xh60.millimeterSize == MeasurementSize(width: .millimeters(40), height: .millimeters(60)))
        #expect(JapanIDPhotoSize.w45xh60.millimeterSize == MeasurementSize(width: .millimeters(45), height: .millimeters(60)))
    }

    @Test("基準サイズの寸法が DNP 仕様と一致する")
    func standardSizeDimensionsMatchSpecification() {
        #expect(JapanIDPhotoSize.w24xh30.millimeterSize == MeasurementSize(width: .millimeters(24), height: .millimeters(30)))
        #expect(JapanIDPhotoSize.w25xh30.millimeterSize == MeasurementSize(width: .millimeters(25), height: .millimeters(30)))
        #expect(JapanIDPhotoSize.w30xh40.millimeterSize == MeasurementSize(width: .millimeters(30), height: .millimeters(40)))
        #expect(JapanIDPhotoSize.w35xh45.millimeterSize == MeasurementSize(width: .millimeters(35), height: .millimeters(45)))
        #expect(JapanIDPhotoSize.w50xh70.millimeterSize == MeasurementSize(width: .millimeters(50), height: .millimeters(70)))
    }

    @Test("allCases が高さ→横幅の昇順に並んでいる")
    func allCasesAreSortedByHeightThenWidth() {
        let sizes: [MeasurementSize] = JapanIDPhotoSize.allCases.map(\.millimeterSize)

        #expect(sizes.count == JapanIDPhotoSize.allCases.count)
        #expect(sizes == sizes.sorted())
    }

    @Test("永続化 ID に重複がない")
    func specificationIDsAreUnique() {
        let allIDs: [String] = JapanIDPhotoSize.allCases.map(\.id)

        #expect(Set(allIDs).count == allIDs.count)

        #expect(allIDs.contains(OriginalSizeSpecification.original.id) == false)
        #expect(allIDs.contains(JapanIDPhotoSize.reservedPassportSpecificationID) == false)
    }
}
