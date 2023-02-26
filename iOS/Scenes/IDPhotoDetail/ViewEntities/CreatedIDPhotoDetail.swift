//
//  CreatedIDPhotoDetail.swift
//  Simple ID Photo
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

let mockHistoriesData: [CreatedIDPhotoDetail] = Array(0...12)
    .map { number in
        let photoSizeType: IDPhotoSizeVariant = .allCases.randomElement() ?? .w30_h40
        
        return CreatedIDPhotoDetail(
            idPhotoSizeType: photoSizeType,
            createdAt: Calendar.current.date(byAdding: .month, value: -number, to: Date())!,
            createdUIImage: UIImage(named: "SampleIDPhoto")!
        )
    }
