//
//  IDPhotoSizeVariant.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2023/01/20
//
//

import Foundation

public enum IDPhotoSizeVariant: CaseIterable {
    
    case original
    
    case passport
    
    case w24_h30
    case w25_h30
    case w30_h30
    case w30_h40
    case w35_h45
    case w40_h50
    case w40_h55
    case w40_h60
    case w45_h60
    case w50_h50
    
    var photoSize: IDPhotoSize {
        let GENERIC_MARGIN_TOP: Measurement<UnitLength> = .init(value: 4, unit: .millimeters)
        
        let GENERIC_FACE_HEIGHT_PERCENTAGE: Double = (60 / 100)
        
        switch self {

        case .original:
            let width: Measurement<UnitLength> = .init(value: .zero, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: .zero, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: .zero, unit: .millimeters)
            
            let marginTop: Measurement<UnitLength> = .init(value: .zero, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: marginTop)
            
        case .passport:
            let width: Measurement<UnitLength> = .init(value: 35, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: 45, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: 34, unit: .millimeters)
            
            let marginTop: Measurement<UnitLength> = .init(value: 4, unit: .millimeters)
            let marginBottom: Measurement<UnitLength> = .init(value: 7, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: marginTop, marginBottom: marginBottom)
            
        case .w24_h30:
            let width: Measurement<UnitLength> = .init(value: 24, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: 30, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: height.value * GENERIC_FACE_HEIGHT_PERCENTAGE, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: GENERIC_MARGIN_TOP)
            
        case .w25_h30:
            let width: Measurement<UnitLength> = .init(value: 25, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: 30, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: height.value * GENERIC_FACE_HEIGHT_PERCENTAGE, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: GENERIC_MARGIN_TOP)
            
        case .w30_h30:
            let width: Measurement<UnitLength> = .init(value: 30, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: 30, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: height.value * GENERIC_FACE_HEIGHT_PERCENTAGE, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: GENERIC_MARGIN_TOP)
            
        case .w30_h40:
            let width: Measurement<UnitLength> = .init(value: 30, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: 40, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: height.value * GENERIC_FACE_HEIGHT_PERCENTAGE, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: GENERIC_MARGIN_TOP)
            
        case .w35_h45:
            let width: Measurement<UnitLength> = .init(value: 35, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: 45, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: height.value * GENERIC_FACE_HEIGHT_PERCENTAGE, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: GENERIC_MARGIN_TOP)
            
        case .w40_h50:
            let width: Measurement<UnitLength> = .init(value: 40, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: 50, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: height.value * GENERIC_FACE_HEIGHT_PERCENTAGE, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: GENERIC_MARGIN_TOP)
            
        case .w40_h55:
            let width: Measurement<UnitLength> = .init(value: 40, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: 55, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: height.value * GENERIC_FACE_HEIGHT_PERCENTAGE, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: GENERIC_MARGIN_TOP)
            
        case .w40_h60:
            let width: Measurement<UnitLength> = .init(value: 40, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: 60, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: height.value * GENERIC_FACE_HEIGHT_PERCENTAGE, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: GENERIC_MARGIN_TOP)
            
        case .w45_h60:
            let width: Measurement<UnitLength> = .init(value: 45, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: 60, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: height.value * GENERIC_FACE_HEIGHT_PERCENTAGE, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: GENERIC_MARGIN_TOP)
            
        case .w50_h50:
            let width: Measurement<UnitLength> = .init(value: 50, unit: .millimeters)
            let height: Measurement<UnitLength> = .init(value: 50, unit: .millimeters)
            
            let faceHeight: Measurement<UnitLength> = .init(value: height.value * GENERIC_FACE_HEIGHT_PERCENTAGE, unit: .millimeters)
            
            return IDPhotoSize(width: width, height: height, faceHeight: faceHeight, marginTop: GENERIC_MARGIN_TOP)
        }
    }
}

extension IDPhotoSizeVariant {
    var purposeInJapan: [String] {
        
        switch self {
            
        case .original:
            return []
            
        case .passport:
            return [
                "パスポート申請",
                "マイナンバー個人番号カード申請",
                "司法試験受験",
                "気象予報士免許受検",
                "宅地建物取引士資格試験",
                "国外運転免許申請 (2022年5月13日~)"
            ]
            
        case .w24_h30:
            return [
                "自動車運転免許証更新用証明写真",
                "電気通信主任技術者受験",
                "衛生管理者 (免許申請)",
                "ボイラー技士 (免許申請)",
                "ガス溶接作業主任者 (免許申請)",
                "工事担当者 (受験・免許申請)",
                "インテリアコーディネーター (受験)",
                "実用英語技能検定受験（1～3級）",
                "アマチュア無線免許 1 級～4 級 (受験・免許申請)",
                "無線従事者 (受験・免許申請)",
                "通信士 (受験・免許申請)"
            ]
            
        case .w25_h30:
            return ["雇用保険受給申請"]
            
        case .w30_h30:
            return ["秘書技能検定面接（1級・準1級）"]
            
        case .w30_h40:
            return [
                "履歴書用証明写真",
                "国家公務員試験 1 種・2 種・3 種 (受験)",
                "大学センター試験 (受験)",
                "身体障害者手帳申請用",
                "宅地建物取引業申請 (東京都・自治体によって異なる)",
                "防火管理者受講申請用 (場所によって異なる)",
                "職業訓練指導員 (受験)",
                "日本語教育能力検定 (受験)",
                "漢字検定 (受験)",
                "情報処理技術者 (受験)",
                "行政書士 （受験）",
                "1 級・2 級建築経理士 (受験)",
                "3 級・4 級建設業務経理士 (受験)",
                "ソムリエ (本人確認用)",
                "在留カード交付申請用",
                "TOEIC (受験)",
                "インテリアプランナー (登録申請)",
                "計量士 (受験)",
                "東京都立高校入学願書用"
            ]
            
        case .w35_h45:
            return [
                "個人番号カード交付申請書用 (マイナンバー)",
                "危険物取扱者 (受験)",
                "公害防止管理者 (受験)",
                "車両系建設機械運転技能者 (修了証明書用)",
                "消防設備士 (受験)",
                "消防設備士免許 (自治体によって異なる)",
                "電気工事士 (受験)",
                "電気主任技術者 (受験)",
                "小型船舶操縦士免許交付申請",
                "水路測量技術検定試験 (受験)",
                "司法試験用 (詳細規定有)",
                "税理士試験用 (詳細規定有)",
                "社会保険労務士 (受験)",
                "中小企業診断士 (受験)",
                "インテリアプランナー (受験)",
                "カラーコーディネーター検定 (受験)",
                "通訳案内士 (受験)",
                "ファイナンシャルプランナー",
                "国内旅行業務取扱管理者 (受験)",
                "総合旅行業務取扱管理者 (受験)",
                "理容師・美容師 (受験)",
                "一級建築士 (免許申請)",
                "二級建築士 (受験)",
                "木造建築士 (受験)",
                "土木施行管理技士 (受験)",
                "管工事施工管理技士 (受験)",
                "建築物環境衛生管理技術者 (受験)",
                "測量士・測量士補 (受験)",
                "技術士・技術士補 (受験)",
                "宅地建物取引士 (受験)",
                "中小企業診断士 (受験)",
                "弁理士 (受験)",
                "Taspoカード申し込み"
            ]
            
        case .w40_h50:
            return [
                "国際自動車免許申請",
                "社会保険労務士 (受験)"
            ]
            
        case .w40_h55:
            return [
                "一級建築士 (受験)"
            ]
            
        case .w40_h60:
            return [
                "医師国家試験 (受験)",
                "看護師試験 (受験)",
                "管理栄養士試験 (受験)",
                "歯科衛生士試験 (受験)",
                "薬剤師試験 (受験)",
                "理学療法士試験 (受験)"
            ]
            
        case .w45_h60:
            return ["自動車整備士 (受験)"]
            
        case .w50_h50:
            return [
                "司法書士 (受験・免許申請)",
                "土地家屋調査士 (受験)"
            ]
        }
    }
}
