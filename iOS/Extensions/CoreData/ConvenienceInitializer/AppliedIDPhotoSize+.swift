//
//  AppliedIDPhotoSize+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/01
//  
//

import CoreData

extension AppliedIDPhotoSize {
    convenience init(
        on context: NSManagedObjectContext,
        id: UUID = .init(),
        millimetersHeight: Double,
        millimetersWidth: Double,
        sizeVariant: IDPhotoSizeVariant,
        faceHeight: AppliedIDPhotoFaceHeight? = nil,
        marginsAroundFace: AppliedMarginsAroundFace? = nil,
        generatedIDPhoto: GeneratedIDPhoto? = nil
    ) {
        self.init(context: context)
        
        self.id = id
        
        self.millimetersHeight = millimetersHeight
        self.millimetersWidth = millimetersWidth
        self.sizeVariant = Int32(sizeVariant.rawValue)
        
        self.faceHeight = faceHeight
        self.marginsAroundFace = marginsAroundFace
        self.generatedIDPhoto = generatedIDPhoto
    }
}
