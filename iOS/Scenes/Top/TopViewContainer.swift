//
//  TopViewContainer.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/07
//  
//

import SwiftUI

struct TopViewContainer: View {
    @State private var shouldShowPicturePickerView: Bool = false
    
    @State private var shouldShowCameraView: Bool = false
    
    @State private var pictureURL: URL? = nil
    
    func showPicturePickerView() -> Void {
        shouldShowPicturePickerView = true
    }
    
    func showCameraView() -> Void {
        shouldShowCameraView = true
    }
    
    var body: some View {
        TopView(
            onTapSelectFromAlbumButton: {
                showPicturePickerView()
            },
            onTapTakePictureButton: {
                showCameraView()
            }
        )
        .fullScreenCover(isPresented: $shouldShowPicturePickerView) {
            PicturePickerView(pictureURL: $pictureURL)
        }
        .fullScreenCover(isPresented: $shouldShowCameraView) {
            CameraView(pictureURL: $pictureURL)
        }
    }
}

struct TopViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        let screenSizeHelper: ScreenSizeHelper = .shared
        
        NavigationView {
            GeometryReader { geometry in
                TopViewContainer()
                    .onAppear {
                        screenSizeHelper.update(screenWidth: geometry.size.width, screenHeight: geometry.size.height)
                    }
                    .onChange(of: geometry.size) { (screenSize: CGSize) in
                        screenSizeHelper.update(screenWidth: screenSize.width, screenHeight: screenSize.height)
                    }
            }
            .environmentObject(screenSizeHelper)
        }
    }
}
