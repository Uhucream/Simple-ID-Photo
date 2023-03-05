//
//  SavedFilePath.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/05
//  
//

import Foundation
import CoreData

extension SavedFilePath {
    static func createNewRecord(
        on context: NSManagedObjectContext,
        id: UUID = .init(),
        rootSearchPathDirectory: FileManager.SearchPathDirectory,
        relativePathFromRootSearchPath: String,
        createdIDPhoto: CreatedIDPhoto? = nil,
        sourcePhoto: SourcePhoto? = nil
    ) -> Void {
        let newRecord: SavedFilePath = .init(context: context)
        
        newRecord.id = id
        newRecord.rootSearchPathDirectory = Int64(rootSearchPathDirectory.rawValue)
        newRecord.relativePathFromRootSearchPath = relativePathFromRootSearchPath
        
        newRecord.createdIDPhoto = createdIDPhoto
        newRecord.sourcePhoto = sourcePhoto
    }
}
