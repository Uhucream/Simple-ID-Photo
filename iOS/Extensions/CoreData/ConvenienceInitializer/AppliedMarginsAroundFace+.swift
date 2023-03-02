//
//  AppliedMarginsAroundFace+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/01
//  
//

import CoreData

extension AppliedMarginsAroundFace {
    convenience init(
        on context: NSManagedObjectContext,
        id: UUID = .init(),
        bottom: Double,
        top: Double,
        idPhotoSize: AppliedIDPhotoSize? = nil
    ) {
        self.init(context: context)
        
        self.id = id
        
        self.bottom = bottom
        self.top = top
        
        self.idPhotoSize = idPhotoSize
    }
}
