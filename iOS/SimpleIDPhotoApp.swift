//
//  SimpleIDPhotoApp.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import SwiftUI

@main
struct SimpleIDPhotoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
