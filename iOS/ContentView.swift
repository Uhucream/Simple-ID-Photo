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
    
    @EnvironmentObject var screenSizeHelper: ScreenSizeHelper

    var body: some View {
        GeometryReader { rootGeometry in
            RootView()
                .onAppear {
                    screenSizeHelper
                        .updateSafeAreaInsets(rootGeometry.safeAreaInsets)
                    
                    screenSizeHelper.updateScreenSize(rootGeometry.size)
                }
                .onChange(of: rootGeometry.safeAreaInsets) { newSafeAreaInsets in
                    screenSizeHelper
                        .updateSafeAreaInsets(newSafeAreaInsets)
                }
                .onChange(of: rootGeometry.size) { (screenSize: CGSize) -> Void in
                    screenSizeHelper.updateScreenSize(screenSize)
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ScreenSizeHelper.shared)
    }
}
