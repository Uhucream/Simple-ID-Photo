//
//  SimpleIDPhotoApp_iOS.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import SwiftUI

let projectGlobalMeasurementFormatter: MeasurementFormatter = {
    let formatter: MeasurementFormatter = .init()
    
    formatter.unitOptions = [
        .providedUnit,
    ]
    
    return formatter
}()

@main
struct SimpleIDPhotoApp_iOS: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var inAppPurchaseHelper: InAppPurchaseHelper = .init()
    
    @StateObject private var appStorageStore: AppStorageStore = .shared

    let persistenceController = PersistenceController.shared
    
    let screenSizeHelper: ScreenSizeHelper = .shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(screenSizeHelper)
                .environmentObject(inAppPurchaseHelper)
                .environmentObject(appStorageStore)
        }
    }
}
