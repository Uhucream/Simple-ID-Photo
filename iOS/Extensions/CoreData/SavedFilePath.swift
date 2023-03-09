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

extension SavedFilePath {
    func parseToDirectoryFileURL(
        defaultRootSearchPathDirectory: FileManager.SearchPathDirectory = .libraryDirectory,
        fileManager: FileManager = .default
    ) -> URL? {
        
        let rootSearchPathDirectory: FileManager.SearchPathDirectory = .init(
            rawValue: UInt(rootSearchPathDirectory)
        ) ?? defaultRootSearchPathDirectory
        
        let rootSearchPathDirectoryURL: URL? = fileManager.urls(
            for: rootSearchPathDirectory,
            in: .userDomainMask
        ).first
        
        guard let rootSearchPathDirectoryURL = rootSearchPathDirectoryURL else { return nil }
        
        guard let relativePathFromRootSearchPath = relativePathFromRootSearchPath else { return nil }
        
        let directoryURL: URL = rootSearchPathDirectoryURL
            .appendingPathComponent(relativePathFromRootSearchPath, conformingTo: .fileURL)
        
        var objcTrue: ObjCBool = .init(true)
        
        let isDirectoryExists: Bool = fileManager.fileExists(atPath: directoryURL.path, isDirectory: &objcTrue)
        
        guard isDirectoryExists else { return nil }
        
        return directoryURL
    }
}
