//
//  Simple_ID_PhotoApp.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import SwiftUI

@main
struct Simple_ID_PhotoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
