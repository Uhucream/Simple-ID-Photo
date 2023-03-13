//
//  ConfirmSaveViewContainer.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/02/16
//  
//

import SwiftUI
import Percentage

struct PaperSize {

    let width: Measurement<UnitLength>
    let height: Measurement<UnitLength>
    
    func cgSize(pixelDensity: Double = 350) -> CGSize {
        let pixelSize: CGSize = .init(
            width: self.width.converted(to: .inches).value * pixelDensity,
            height: self.height.converted(to: .inches).value * pixelDensity
        )
        
        return pixelSize
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path: Path = .init()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        path.closeSubpath()
        
        return path
    }
}

fileprivate struct PrintSizeGuideView<Content: View>: View {

    private let  SIZE_GUIDE_BORDER_WIDTH: Double = 2
    
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        GeometryReader { geometry in
            let triangleWidth: CGFloat = 5%.of(geometry.size.width)
            
            ZStack {
                VStack(alignment: .center, spacing: 0) {
                    Triangle()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: triangleWidth)
                    
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 0) {
                        Triangle()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: triangleWidth)
                            .rotationEffect(Angle(degrees: -90))
                        
                        Spacer()
                        
                        Triangle()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: triangleWidth)
                            .rotationEffect(Angle(degrees: 90))
                    }
                    
                    Spacer()
                    
                    Triangle()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: triangleWidth)
                        .rotationEffect(Angle(degrees: 180))
                }
                
                content()
                    .padding(triangleWidth)
            }
            .padding(self.SIZE_GUIDE_BORDER_WIDTH)
            .border(Color.fixedBlack, width: self.SIZE_GUIDE_BORDER_WIDTH)
        }
    }
}

fileprivate struct IDPhotoWithSizeGuide: View {

    var idPhotoUIImage: UIImage
    var idPhotoCGSize: CGSize
    
    init(
        idPhotoUIImage: UIImage,
        idPhotoCGSize: CGSize
    ) {
        self.idPhotoUIImage = idPhotoUIImage
        self.idPhotoCGSize = idPhotoCGSize
    }
    
    var body: some View {
        PrintSizeGuideView {
            Image(uiImage: idPhotoUIImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: idPhotoCGSize.width)
        }
    }
}

struct ConfirmSaveViewContainer: View {

    @State private var idPhotoForSavingUIImage: UIImage? = nil
    
    var sourceIDPhotoUIImage: UIImage?
    var sourceIDPhotoSizeVariant: IDPhotoSizeVariant
    
    init(
        sourceIDPhotoUIImage: UIImage?,
        sourceIDPhotoSizeVariant: IDPhotoSizeVariant
    ) {
        _idPhotoForSavingUIImage = .init(initialValue: sourceIDPhotoUIImage)
        
        self.sourceIDPhotoUIImage = sourceIDPhotoUIImage
        
        self.sourceIDPhotoSizeVariant = sourceIDPhotoSizeVariant
    }
    
    @MainActor
    func generateIDPhotoForPrinting() -> Void {
        
        guard let sourceIDPhotoUIImage: UIImage = self.sourceIDPhotoUIImage else { return }
        
        @ViewBuilder
        var imageRendererSourceView: some View {
            let idPhotoCGSize: CGSize = self.sourceIDPhotoSizeVariant.photoSize.cgsize(pixelDensity: 350)
            
            let idPhotoRoundedCGSize: CGSize = .init(
                width: idPhotoCGSize.width,
                height: idPhotoCGSize.height
            )
            
            IDPhotoWithSizeGuide(
                idPhotoUIImage: sourceIDPhotoUIImage,
                idPhotoCGSize: idPhotoRoundedCGSize
            )
            .background(Color.fixedWhite)
        }
        
        var printingPaperCGSize: CGSize {
            let photo3RPaperSize: PaperSize = .init(
                width: .init(value: 89, unit: .millimeters),
                height: .init(value: 127, unit: .millimeters)
            )
            
            return photo3RPaperSize.cgSize()
        }
        
        let printingPaperRoundedCGSize: CGSize = .init(
            width: printingPaperCGSize.width.rounded(),
            height: printingPaperCGSize.height.rounded()
        )
        
        if #available(iOS 16, *) {
            
            let imageRenderer: ImageRenderer = .init(content: imageRendererSourceView)
            
            imageRenderer.scale = 1
            imageRenderer.proposedSize = .init(printingPaperRoundedCGSize)
            
            guard let generatedUIImage: UIImage = imageRenderer.uiImage else { return }
            
            self.idPhotoForSavingUIImage = generatedUIImage
        } else {
            
            let renderSourceViewHostingController: UIHostingController = .init(
                rootView: imageRendererSourceView
                    .background(Color.fixedWhite)
                    .frame(width: printingPaperRoundedCGSize.width, height: printingPaperRoundedCGSize.height)
                    .edgesIgnoringSafeArea(.top)
            )
            
            renderSourceViewHostingController.view.bounds = .init(origin: .zero, size: printingPaperRoundedCGSize)
            
            let sourceUIView: UIView! = renderSourceViewHostingController.view
            
            let imageRendererFormat: UIGraphicsImageRendererFormat = .init()
            
            imageRendererFormat.scale = 1
            
            let imageRenderer: UIGraphicsImageRenderer = .init(bounds: sourceUIView.bounds, format: imageRendererFormat)
            
            let generatedUIImage = imageRenderer.image { _ in
                sourceUIView.drawHierarchy(in: sourceUIView.bounds, afterScreenUpdates: true)
            }
            
            self.idPhotoForSavingUIImage = generatedUIImage
        }
    }
    
    var body: some View {
        ConfirmSaveView(
            previewImageForSavingUIImage: $idPhotoForSavingUIImage
        )
        .onAppear {
            Task(priority: .high) {
                generateIDPhotoForPrinting()
            }
        }
    }
}

struct ConfirmSaveViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmSaveViewContainer(
            sourceIDPhotoUIImage: .init(named: "SampleIDPhoto"),
            sourceIDPhotoSizeVariant: .w24_h30
        )
    }
}
