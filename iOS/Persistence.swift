//
//  Persistence.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        mockHistoriesData
            .enumerated()
            .forEach { (index: Int, history: CreatedIDPhotoDetail) in
                
                let sourcePhoto: SourcePhoto = .init(
                    on: viewContext,
                    imageURL: history.createdUIImage.localURLForXCAssets(fileName: "SampleIDPhoto")!.absoluteString,
                    shotDate: Calendar.current.date(byAdding: .month, value: -(index + 1), to: .now)
                )
                
                let appliedBackgroundColor: AppliedBackgroundColor = .init(
                    on: viewContext,
                    color: .idPhotoBackgroundColors.blue
                )
                
                let appliedIDPhotoFaceHeight: AppliedIDPhotoFaceHeight = .init(
                    on: viewContext,
                    millimetersHeight: history.idPhotoSizeType.photoSize.faceHeight.value
                )
                
                let appliedMarginsAroundFace: AppliedMarginsAroundFace = .init(
                    on: viewContext,
                    bottom: history.idPhotoSizeType.photoSize.marginBottom?.value ?? -1,
                    top: history.idPhotoSizeType.photoSize.marginTop.value
                )
                
                let appliedIDPhotoSize: AppliedIDPhotoSize = .init(
                    on: viewContext,
                    millimetersHeight: history.idPhotoSizeType.photoSize.height.value,
                    millimetersWidth: history.idPhotoSizeType.photoSize.width.value,
                    sizeVariant: history.idPhotoSizeType,
                    faceHeight: appliedIDPhotoFaceHeight,
                    marginsAroundFace: appliedMarginsAroundFace
                )
                
                let generatedIDPhoto: GeneratedIDPhoto = .init(
                    on: viewContext,
                    createdAt: history.createdAt,
                    imageURL: history.createdUIImage.localURLForXCAssets(fileName: "SampleIDPhoto")!.absoluteString,
                    updatedAt: .now,
                    appliedBackgroundColor: appliedBackgroundColor,
                    appliedIDPhotoSize: appliedIDPhotoSize,
                    sourcePhoto: sourcePhoto
                )
            }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SimpleIDPhoto")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
