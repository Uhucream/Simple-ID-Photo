//
//  SourcePhoto+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/01
//  
//

import CoreData

extension SourcePhoto {
    convenience init(
        on context: NSManagedObjectContext,
        id: UUID = .init(),
        imageURL: String?,
        shotDate: Date?,
        createdIDPhoto: CreatedIDPhoto? = nil
    ) {
        self.init(context: context)
        
        self.id = id
        
        self.imageURL = imageURL
        self.shotDate = shotDate
        
        self.createdIDPhoto = createdIDPhoto
    }
}
