//
//  CreatedIDPhotoDetail.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/02/26
//  
//

import Foundation
import SwiftUI

struct CreatedIDPhotoDetail: Identifiable {
    
    var id: UUID = .init()
    
    let idPhotoSizeType: IDPhotoSizeVariant
    
    let createdAt: Date
    
    let createdUIImage: UIImage
}

private let allIDPhotoSizeVariants: [IDPhotoSizeVariant] = IDPhotoSizeVariant.allCases

private let startOfToday: Date = Calendar.current.startOfDay(for: .now)

let mockHistoriesData: [CreatedIDPhotoDetail] = allIDPhotoSizeVariants.indices
    .map { (index) in
        return CreatedIDPhotoDetail(
            idPhotoSizeType: allIDPhotoSizeVariants[index],
            createdAt: Calendar.current.date(byAdding: .month, value: -index, to: startOfToday)!,
            createdUIImage: UIImage(named: "SampleIDPhoto")!
        )
    }
