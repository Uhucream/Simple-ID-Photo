//
//  ContentView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import SwiftUI
import CoreData

struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var screenSizeHelper: ScreenSizeHelper

    var body: some View {
        GeometryReader { rootGeometry in
            RootView()
                .onAppear {
                    screenSizeHelper
                        .updateSafeAreaInsets(rootGeometry.safeAreaInsets)
                    
                    screenSizeHelper
                        .updateScreenSize(
                            screenWidth: rootGeometry.size.width,
                            screenHeight: rootGeometry.size.height
                        )
                }
                .onChange(of: rootGeometry.safeAreaInsets) { newSafeAreaInsets in
                    screenSizeHelper
                        .updateSafeAreaInsets(newSafeAreaInsets)
                }
                .onChange(of: rootGeometry.size) { (screenSize: CGSize) -> Void in
                    screenSizeHelper
                        .updateScreenSize(
                            screenWidth: screenSize.width,
                            screenHeight: screenSize.height
                        )
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
//            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(ScreenSizeHelper.shared)
    }
}
