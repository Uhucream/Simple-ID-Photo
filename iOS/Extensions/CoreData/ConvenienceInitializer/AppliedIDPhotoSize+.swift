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
        sizeSpecificationID: String?,
        millimetersWidth: Double,
        millimetersHeight: Double,
        createdIDPhoto: CreatedIDPhoto? = nil
    ) {
        self.init(context: context)

        self.id = id

        self.sizeSpecificationID = sizeSpecificationID

        self.millimetersWidth = millimetersWidth
        self.millimetersHeight = millimetersHeight

        self.createdIDPhoto = createdIDPhoto
    }

    convenience init(
        on context: NSManagedObjectContext,
        id: UUID = .init(),
        sizeSpecification: any IDPhotoSizeSpecification,
        createdIDPhoto: CreatedIDPhoto? = nil
    ) {
        self.init(
            on: context,
            id: id,
            sizeSpecificationID: sizeSpecification.id,
            millimetersWidth: sizeSpecification.millimeterSize?.width.converted(to: .millimeters).value ?? .zero,
            millimetersHeight: sizeSpecification.millimeterSize?.height.converted(to: .millimeters).value ?? .zero,
            createdIDPhoto: createdIDPhoto
        )
    }
}
