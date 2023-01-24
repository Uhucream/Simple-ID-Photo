//
//  CreateIDPhotoViewContainer.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2023/01/11
//
//

import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import VideoToolbox

struct CreateIDPhotoViewContainer: View {
    @ObservedObject var visionIDPhotoGenerator: VisionIDPhotoGenerator
    
    @State private var previewUIImage: UIImage? = nil
    
    @State private var selectedIDPhotoSize: IDPhotoSizeVariant = .original
    
    init(sourceCIImage: CIImage?) {
        
        self.visionIDPhotoGenerator = .init(sourceCIImage: sourceCIImage)
        
        if let unwrappedSourceUIImage = sourceCIImage?.uiImage(orientation: .up) {
            _previewUIImage = State(initialValue: unwrappedSourceUIImage)
        }
    }
    
    func refreshPreviewImage(newImage: UIImage) -> Void {
        self.previewUIImage = newImage
    }
    
    var body: some View {
        CreateIDPhotoView(
            selectedBackgroundColor: $visionIDPhotoGenerator.idPhotoBackgroundColor,
            selectedIDPhotoSize: $selectedIDPhotoSize,
            previewUIImage: $previewUIImage.animation()
        )
        .task {
            try? await visionIDPhotoGenerator.performPersonSegmentationRequest()
        }
        .onChange(of: visionIDPhotoGenerator.idPhotoBackgroundColor)  { _ in
            Task {
                try? await visionIDPhotoGenerator.performPersonSegmentationRequest()
            }
        }
        .onChange(of: visionIDPhotoGenerator.generatedIDPhoto) { newGeneratedIDPhoto in
            guard let newGeneratedIDPhotoUIImage: UIImage = newGeneratedIDPhoto?.uiImage(orientation: .up) else { return }
            
            self.refreshPreviewImage(newImage: newGeneratedIDPhotoUIImage)
        }
        .toolbar(.hidden)
    }
}

struct CreateIDPhotoViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUIImage: UIImage = UIImage(named: "TimCook")!
        
        NavigationView {
            CreateIDPhotoViewContainer(sourceCIImage: .init(image: sampleUIImage))
        }
    }
}
