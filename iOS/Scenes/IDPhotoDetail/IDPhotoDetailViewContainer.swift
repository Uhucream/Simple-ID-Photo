//
//  IDPhotoDetailViewContainer.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/01
//  
//

import SwiftUI

struct IDPhotoDetailViewContainer: View {
    
    @ObservedObject var createdIDPhoto: CreatedIDPhoto
    
    var body: some View {
        VStack {
            IDPhotoDetailView(
                idPhotoImageURL: Binding<URL?>(
                    get: {
                        let imageURLString: String? = createdIDPhoto.imageFileName
                        let imageURL: URL? = .init(string: imageURLString ?? "")
                        
                        return imageURL
                    },
                    set: { (newImageURL) in
                        self.createdIDPhoto.imageFileName = newImageURL?.absoluteString
                    }
                ),
                idPhotoSizeType: Binding<IDPhotoSizeVariant>(
                    get: {
                        let appliedIDPhotoSize = createdIDPhoto.appliedIDPhotoSize
                        let idPhotoSizeVariant: IDPhotoSizeVariant = IDPhotoSizeVariant(rawValue: Int(appliedIDPhotoSize?.sizeVariant ?? 0)) ?? .original
                        
                        return idPhotoSizeVariant
                    },
                    set: { (newIDPhotoSizeVariant) in
                        createdIDPhoto.appliedIDPhotoSize?.sizeVariant = Int32(newIDPhotoSizeVariant.rawValue)
                    }
                ),
                createdAt: Binding<Date>(
                    get: {
                        let createdDate: Date = createdIDPhoto.createdAt ?? .distantPast
                        
                        return createdDate
                    },
                    set: { (newDate) in
                        createdIDPhoto.createdAt = newDate
                    }
                )
            )
        }
    }
}

struct IDPhotoDetailViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            let mockCreatedIDPhoto: CreatedIDPhoto = .init(
                on: PersistenceController.preview.container.viewContext,
                createdAt: .now.addingTimeInterval(-1000),
                imageFileName: nil,
                updatedAt: .now
            )
            
            IDPhotoDetailViewContainer(createdIDPhoto: mockCreatedIDPhoto)
        }
    }
}
