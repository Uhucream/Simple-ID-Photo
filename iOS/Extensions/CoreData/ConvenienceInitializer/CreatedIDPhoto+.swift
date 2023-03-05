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
        imageFileName: String?,
        updatedAt: Date?,
        appliedBackgroundColor: AppliedBackgroundColor? = nil,
        appliedIDPhotoSize: AppliedIDPhotoSize? = nil,
        savedDirectory: SavedFilePath? = nil,
        sourcePhoto: SourcePhoto? = nil
    ) {
        self.init(context: context)
        
        self.id = id
        
        self.createdAt = createdAt
        self.imageFileName = imageFileName
        self.updatedAt = updatedAt
        
        self.appliedBackgroundColor = appliedBackgroundColor
        self.appliedIDPhotoSize = appliedIDPhotoSize
        self.savedDirectory = savedDirectory
        self.sourcePhoto = sourcePhoto
    }
}
