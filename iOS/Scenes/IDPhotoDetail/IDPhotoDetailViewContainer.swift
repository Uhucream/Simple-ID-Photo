//
//  IDPhotoDetailViewContainer.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/01
//  
//

import SwiftUI

struct IDPhotoDetailViewContainer: View {
    
    @State private var idPhotoUIImage: UIImage
    @State private var idPhotoSizeType: IDPhotoSizeVariant
    @State private var createdAt: Date
    
    init(_ createdIDPhotoDetail: CreatedIDPhotoDetail) {
        _idPhotoUIImage = .init(initialValue: createdIDPhotoDetail.createdUIImage)
        _idPhotoSizeType = .init(initialValue: createdIDPhotoDetail.idPhotoSizeType)
        _createdAt = .init(initialValue: createdIDPhotoDetail.createdAt)
    }
    
    var body: some View {
        VStack {
            IDPhotoDetailView(
                idPhotoUIImage: $idPhotoUIImage,
                idPhotoSizeType: $idPhotoSizeType,
                createdAt: $createdAt
            )
        }
    }
}

struct IDPhotoDetailViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IDPhotoDetailViewContainer(mockHistoriesData[0])
        }
    }
}
