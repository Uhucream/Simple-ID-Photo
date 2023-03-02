//
//  AppliedIDPhotoFaceHeight+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/01
//  
//

import CoreData

extension AppliedIDPhotoFaceHeight {
    convenience init(
        on context: NSManagedObjectContext,
        id: UUID = .init(),
        millimetersHeight: Double,
        idPhotoSize: AppliedIDPhotoSize? = nil
    ) {
        self.init(context: context)
        
        self.id = id
        
        self.millimetersHeight = millimetersHeight
        self.idPhotoSize = idPhotoSize
    }
}
