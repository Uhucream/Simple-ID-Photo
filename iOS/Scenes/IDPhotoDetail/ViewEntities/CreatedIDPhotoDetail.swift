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

    let sizeSpecification: any IDPhotoSizeSpecification

    let createdAt: Date

    let createdUIImage: UIImage
}

private let startOfToday: Date = Calendar.current.startOfDay(for: .now)

let mockHistoriesData: [CreatedIDPhotoDetail] = JapanIDPhotoSizes.pickerLineup.indices
    .map { (index) in
        return CreatedIDPhotoDetail(
            sizeSpecification: JapanIDPhotoSizes.pickerLineup[index],
            createdAt: Calendar.current.date(byAdding: .month, value: -index, to: startOfToday)!,
            createdUIImage: UIImage(named: "SampleIDPhoto")!
        )
    }
