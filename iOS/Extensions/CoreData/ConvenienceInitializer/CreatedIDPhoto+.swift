//
//  CreatedIDPhoto+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/01
//  
//

import CoreData

extension CreatedIDPhoto {
    convenience init(
        on context: NSManagedObjectContext,
        id: UUID = .init(),
        createdAt: Date?,
        imageURL: String?,
        updatedAt: Date?,
        appliedBackgroundColor: AppliedBackgroundColor? = nil,
        appliedIDPhotoSize: AppliedIDPhotoSize? = nil,
        sourcePhoto: SourcePhoto? = nil
    ) {
        self.init(context: context)
        
        self.id = id
        
        self.createdAt = createdAt
        self.imageURL = imageURL
        self.updatedAt = updatedAt
        
        self.appliedBackgroundColor = appliedBackgroundColor
        self.appliedIDPhotoSize = appliedIDPhotoSize
        self.sourcePhoto = sourcePhoto
    }
}
