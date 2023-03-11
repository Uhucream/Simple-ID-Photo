//
//  SavedFilePath+ConvenienceInitializer.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/05
//  
//

import Foundation
import CoreData

extension SavedFilePath {
    convenience init(
        on context: NSManagedObjectContext,
        id: UUID = .init(),
        rootSearchPathDirectory: FileManager.SearchPathDirectory,
        relativePathFromRootSearchPath: String,
        createdIDPhoto: CreatedIDPhoto? = nil,
        sourcePhoto: SourcePhoto? = nil
    ) {
        self.init(context: context)
        
        self.id = id
        self.rootSearchPathDirectory = Int64(rootSearchPathDirectory.rawValue)
        self.relativePathFromRootSearchPath = relativePathFromRootSearchPath
        
        self.createdIDPhoto = createdIDPhoto
        self.sourcePhoto = sourcePhoto
    }
}
