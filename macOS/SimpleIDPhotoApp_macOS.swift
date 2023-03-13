//
//  SimpleIDPhotoApp_macOS.swift
//  Simple-ID-Photo (macOS)
//  
//  Created by TakashiUshikoshi on 2023/03/14
//  
//

import SwiftUI

@main
struct SimpleIDPhotoApp_macOS: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
