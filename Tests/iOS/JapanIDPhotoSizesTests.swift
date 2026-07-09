//
//  JapanIDPhotoSizesTests.swift
//  Simple ID Photo Tests
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Testing
@testable import SimpleIDPhoto

@Suite("JapanIDPhotoSizes (日本向けサイズ一覧)")
struct JapanIDPhotoSizesTests {

    @Test("旧 IDPhotoSizeVariant の rawValue から仕様書 ID へマッピングできる")
    func legacySizeVariantMapping() {
        //  旧 enum の並び: original(0), passport(1), custom(2), w24_h30(3), w25_h30(4), w30_h30(5),
        //  w30_h40(6), w35_h45(7), w40_h50(8), w40_h55(9), w40_h60(10), w45_h60(11), w50_h50(12)
        #expect(JapanIDPhotoSizes.sizeSpecificationID(fromLegacySizeVariantRawValue: 0) == "original")
        #expect(JapanIDPhotoSizes.sizeSpecificationID(fromLegacySizeVariantRawValue: 1) == "jp.passport")
        #expect(JapanIDPhotoSizes.sizeSpecificationID(fromLegacySizeVariantRawValue: 3) == "jp.w24h30")
        #expect(JapanIDPhotoSizes.sizeSpecificationID(fromLegacySizeVariantRawValue: 5) == "jp.square30")
        #expect(JapanIDPhotoSizes.sizeSpecificationID(fromLegacySizeVariantRawValue: 6) == "jp.w30h40")
        #expect(JapanIDPhotoSizes.sizeSpecificationID(fromLegacySizeVariantRawValue: 7) == "jp.w35h45")
        #expect(JapanIDPhotoSizes.sizeSpecificationID(fromLegacySizeVariantRawValue: 10) == "jp.w40h60")
        #expect(JapanIDPhotoSizes.sizeSpecificationID(fromLegacySizeVariantRawValue: 11) == "jp.w45h60")
    }

    @Test("廃止されたサイズは nil を返す (mm 実寸フォールバックに委ねる)")
    func discontinuedLegacySizesMapToNil() {
        let discontinuedRawValues: [Int32] = [2, 4, 8, 9, 12]

        for rawValue in discontinuedRawValues {
            #expect(JapanIDPhotoSizes.sizeSpecificationID(fromLegacySizeVariantRawValue: rawValue) == nil)
        }
    }

    @Test("ピッカー一覧には w35h45 とパスポートを含めない (パスポート対応完了までの意図的な非表示)")
    func pickerLineupHidesW35H45AndPassport() {
        let pickerLineupIDs: [String] = JapanIDPhotoSizes.pickerLineup.map(\.id)

        #expect(pickerLineupIDs.contains("jp.w35h45") == false)
        #expect(pickerLineupIDs.contains(JapanIDPhotoSizes.passportSizeSpecificationID) == false)

        #expect(pickerLineupIDs.first == "original")
    }

    @Test("ピッカー非表示の w35h45 も、永続化された ID からは解決できる")
    func hiddenSpecificationIsStillResolvable() {
        let resolvedSpecification: (any IDPhotoSizeSpecification)? = JapanIDPhotoSizes.specification(matching: "jp.w35h45")

        #expect(resolvedSpecification?.id == "jp.w35h45")
        #expect(resolvedSpecification?.millimeterSize == MillimeterSize(width: 35, height: 45))
    }

    @Test("派生サイズのカット後寸法が DNP 仕様と一致する")
    func derivedSizeDimensionsMatchSpecification() {
        #expect(JapanIDPhotoSizes.square25.millimeterSize == MillimeterSize(width: 25, height: 25))
        #expect(JapanIDPhotoSizes.square30.millimeterSize == MillimeterSize(width: 30, height: 30))
        #expect(JapanIDPhotoSizes.w40h60.millimeterSize == MillimeterSize(width: 40, height: 60))
        #expect(JapanIDPhotoSizes.w45h60.millimeterSize == MillimeterSize(width: 45, height: 60))
    }

    @Test("一覧内の仕様書 ID に重複がない")
    func specificationIDsAreUnique() {
        let allIDs: [String] = JapanIDPhotoSizes.allSpecifications.map(\.id)

        #expect(Set(allIDs).count == allIDs.count)
    }
}
