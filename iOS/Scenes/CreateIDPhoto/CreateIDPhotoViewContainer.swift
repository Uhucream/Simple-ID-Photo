//
//  CreateIDPhotoViewContainer.swift
//  Simple ID Photo (iOS)
//
//  Created by TakashiUshikoshi on 2023/01/11
//
//

import SwiftUI
import Combine
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import VideoToolbox
import UniformTypeIdentifiers
import Percentage

struct CreateIDPhotoViewContainer: View {
    
    static let CREATED_ID_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH: FileManager.SearchPathDirectory = .libraryDirectory
    static let CREATED_ID_PHOTO_SAVE_FOLDER_NAME: String = "CreatedPhotos"
    
    @Environment(\.managedObjectContext) var viewContext
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject private var screenSizeHelper: ScreenSizeHelper
    
    private var sourcePhotoTemporaryURL: URL
    
    private var sourcePhotoCIImage: CIImage? {
        return .init(contentsOf: sourcePhotoTemporaryURL)
    }
    
    private var orientationFixedSourceUIImage: UIImage? {
        let uiImageFromURL: UIImage = .init(url: sourcePhotoTemporaryURL)
        
        let orientationFixedImage: UIImage? = uiImageFromURL.orientationFixed()
        
        return orientationFixedImage
    }
    
    private var sourceImageOrientation: UIImage.Orientation {
        let uiImageFromURL: UIImage = .init(url: sourcePhotoTemporaryURL)
        
        let orientationFixedImage: UIImage? = uiImageFromURL.orientationFixed()
        
        let orientation: UIImage.Orientation = orientationFixedImage?.imageOrientation ?? .up
        
        return orientation
    }
    
    private var visionFrameworkHelper: VisionFrameworkHelper {
        .init(
            sourceCIImage: sourcePhotoCIImage,
            sourceImageOrientation: .init(sourceImageOrientation)
        )
    }
    
    private var detectedFaceRect: CGRect {
        get async throws {
            try await detectingFaceRect() ?? .zero
        }
    }
    
    private var availableIDPhotoSizeVariants: [IDPhotoSizeVariant] {
        let allVariants: [IDPhotoSizeVariant] = IDPhotoSizeVariant.allCases
        
        let variantsWithoutPassportAndCustom = allVariants.filter { variant in
            
            let isPassport: Bool = variant == .passport
            let isCustom: Bool = variant == .custom
            
            //  MARK: パスポートサイズを除外している都合上、通常の w35_45 だけ表示すると混乱を招く可能性があるので除外
            let is35_45: Bool = variant == .w35_h45
            
            return !(isPassport || isCustom || is35_45)
        }
        
        return variantsWithoutPassportAndCustom
    }
    
    @State private var previewUIImage: UIImage? = nil
    
    @State private var paintedPhotoCIImage: CIImage? = nil
    
    @State private var croppingCGRect: CGRect = .zero
    
    @State private var selectedProcess: IDPhotoProcessSelection = .backgroundColor
    
    @State private var selectedBackgroundColor: Color = .idPhotoBackgroundColors.blue
    @State private var selectedIDPhotoSizeVariant: IDPhotoSizeVariant = .original
    
    @State private var selectedBackgroundColorLabel: String = ""
    
    @State private var shouldDisableButtons: Bool = false
    
    @State private var shouldShowSavingProgressView: Bool = false
    @State private var savingProgressStatus: SavingStatus = .inProgress
    
    @State private var shouldShowDiscardViewConfirmationDialog: Bool = false
    
    private(set) var onDoneCreateIDPhotoProcessCallback: ((CreatedIDPhoto) -> Void)?
    
    init(sourcePhotoURL: URL) {
        
        self.sourcePhotoTemporaryURL = sourcePhotoURL
        
        _previewUIImage = State(initialValue: orientationFixedSourceUIImage)
        
        _croppingCGRect = State(
            initialValue: CGRect(
                origin: .zero,
                size: sourcePhotoCIImage?.extent.size ?? .zero
            )
        )
    }
    
    func onDoneCreateIDPhotoProcess(action: @escaping (CreatedIDPhoto) -> Void) -> Self {
        var view = self
        
        view.onDoneCreateIDPhotoProcessCallback = action
        
        return view
    }
    
    func showDiscardViewConfirmationDialog() -> Void {
        shouldShowDiscardViewConfirmationDialog = true
    }
    
    func detectingFaceRect() async throws -> CGRect? {
        do {
            let detectedRect: CGRect? = try await visionFrameworkHelper.detectFaceIncludingHairRectangle()
            
            return detectedRect
        } catch {
            throw error
        }
    }
    
    func paintingImageBackgroundColor(
        sourceImage: CIImage,
        backgroundColor: Color
    ) async throws -> CIImage? {
        do {
            let solidColorBackgroundUIImage: UIImage? = .init(color: backgroundColor, size: sourceImage.extent.size)
            
            guard let solidColorBackgroundCIImage = solidColorBackgroundUIImage?.ciImage() else { return nil }
            
            let generatedImage: CIImage? = try await visionFrameworkHelper.combineWithBackgroundImage(with: solidColorBackgroundCIImage)
            
            return generatedImage
        } catch {
            throw error
        }
    }
    
    func generateCroppingRect(from sizeVariant: IDPhotoSizeVariant) async -> CGRect? {

        guard let detectedFaceRect = try? await detectedFaceRect else { return nil }
        
        if detectedFaceRect == .zero { return nil }
        
        let faceHeightRatio: Double = sizeVariant.photoSize.faceHeight.value / sizeVariant.photoSize.height.value
        
        let idPhotoAspectRatio: Double = sizeVariant.photoSize.width.value / sizeVariant.photoSize.height.value
        
        let idPhotoHeight: CGFloat = detectedFaceRect.height / faceHeightRatio
        let idPhotoWidth: CGFloat = idPhotoHeight * idPhotoAspectRatio
        
        let marginTopRatio: Double = sizeVariant.photoSize.marginTop.value / sizeVariant.photoSize.height.value
        
        let marginTop: CGFloat = idPhotoHeight * marginTopRatio
        
        let remainderWidthOfFaceAndPhoto: CGFloat = idPhotoWidth - detectedFaceRect.size.width
        
        let originXOfCroppingRect: CGFloat = detectedFaceRect.origin.x - (remainderWidthOfFaceAndPhoto / 2)
        let originYOfCroppingRect: CGFloat = (detectedFaceRect.maxY + marginTop) - idPhotoHeight
        
        let croppingRect: CGRect = .init(
            origin: CGPoint(
                x: originXOfCroppingRect,
                y: originYOfCroppingRect
            ),
            size: CGSize(
                width: idPhotoWidth,
                height: idPhotoHeight
            )
        )
        
        return croppingRect
    }
    
    func croppingImage(
        sourceImage: CIImage,
        sizeVariant: IDPhotoSizeVariant
    ) async -> CIImage? {
        
        guard let detectedFaceRect = try? await detectedFaceRect else { return nil }
        
        if detectedFaceRect == .zero { return nil }
        
        let faceHeightRatio: Double = sizeVariant.photoSize.faceHeight.value / sizeVariant.photoSize.height.value
        
        let idPhotoAspectRatio: Double = sizeVariant.photoSize.width.value / sizeVariant.photoSize.height.value
        
        let idPhotoHeight: CGFloat = detectedFaceRect.height / faceHeightRatio
        let idPhotoWidth: CGFloat = idPhotoHeight * idPhotoAspectRatio
        
        let marginTopRatio: Double = sizeVariant.photoSize.marginTop.value / sizeVariant.photoSize.height.value
        
        let marginTop: CGFloat = idPhotoHeight * marginTopRatio
        
        let remainderWidthOfFaceAndPhoto: CGFloat = idPhotoWidth - detectedFaceRect.size.width
        
        let originXOfCroppingRect: CGFloat = detectedFaceRect.origin.x - (remainderWidthOfFaceAndPhoto / 2)
        let originYOfCroppingRect: CGFloat = (detectedFaceRect.maxY + marginTop) - idPhotoHeight
        
        let croppingRect: CGRect = .init(
            origin: CGPoint(
                x: originXOfCroppingRect,
                y: originYOfCroppingRect
            ),
            size: CGSize(
                width: idPhotoWidth,
                height: idPhotoHeight
            )
        )
        
        let croppedImage = sourceImage.cropped(to: croppingRect)
        
        return croppedImage
    }
    
    //  TODO: パスポートサイズの対応
    //    func cropingImageAsPassportSize(sourceImage: CIImage) -> Void {
    //
    //    }
    
    func composeIDPhoto(
        sourcePhoto: CIImage,
        idPhotoSizeVariant: IDPhotoSizeVariant,
        backgroundColor: Color
    ) async -> CIImage? {
        do {
            var paintedSourcePhoto: CIImage? {
                get async throws {
                    if backgroundColor == .clear {
                        return sourcePhoto
                    }
                    
                    return try await paintingImageBackgroundColor(
                        sourceImage: sourcePhoto,
                        backgroundColor: backgroundColor
                    )
                }
            }
            
            guard let paintedSourcePhoto = try await paintedSourcePhoto else { return nil }
            
            if idPhotoSizeVariant == .original {
                return paintedSourcePhoto
            }
            
            //            if idPhotoSizeVariant == .passport {
            //                let croppedImage: CIImage? = cropingImageAsPassportSize(sourceImage: paintedSourcePhoto)
            //
            //                return croppedImage
            //            }
            
            if idPhotoSizeVariant == .passport {
                return nil
            }
            
            let croppedImage: CIImage? = await croppingImage(sourceImage: paintedSourcePhoto, sizeVariant: idPhotoSizeVariant)
            
            return croppedImage
        } catch {
            print(error)
            
            return nil
        }
    }
    
    func generateBackgroundColorLabel(_ color: Color) -> String {
        switch color {
            
        case .clear:
            return "背景色なし"
            
        case .idPhotoBackgroundColors.blue:
            return "青"
            
        case .idPhotoBackgroundColors.gray:
            return "グレー"
            
        case .idPhotoBackgroundColors.white:
            return "白"
            
        case .idPhotoBackgroundColors.brown:
            return "茶"
            
        default:
            return ""
        }
    }
    
    func handleTapDoneButton() -> Void {
        Task {
            shouldDisableButtons = true
            
            shouldShowSavingProgressView = true
            
            do {
                guard let sourcePhotoCIImage = sourcePhotoCIImage else {
                    shouldDisableButtons = false
                    
                    savingProgressStatus = .failed
                    
                    try await Task.sleep(milliseconds: 1200)
                    
                    shouldShowSavingProgressView = false
                    
                    return
                }
                
                guard let orientationFixedSourceUIImage = orientationFixedSourceUIImage else {
                    shouldDisableButtons = false

                    savingProgressStatus = .failed
                    
                    try await Task.sleep(milliseconds: 1200)
                    
                    shouldShowSavingProgressView = false
                    
                    return
                }
                
                let composedIDPhoto: CIImage? = await self.composeIDPhoto(
                    sourcePhoto: orientationFixedSourceUIImage.ciImage() ?? sourcePhotoCIImage,
                    idPhotoSizeVariant: self.selectedIDPhotoSizeVariant,
                    backgroundColor: self.selectedBackgroundColor
                )
                
                guard let composedIDPhoto = composedIDPhoto else {
                    shouldDisableButtons = false

                    savingProgressStatus = .failed
                    
                    try await Task.sleep(milliseconds: 1200)
                    
                    shouldShowSavingProgressView = false
                    
                    return
                }
                
                let isHEICSupported: Bool = (CGImageDestinationCopyTypeIdentifiers() as! [String]).contains(UTType.heic.identifier)
                
                let saveFileUTType: UTType = isHEICSupported ? .heic : .jpeg
                
                let saveFileName: String = ProcessInfo.processInfo.globallyUniqueString
                
                let saveDestinationDirectoryURL: URL? = fetchOrCreateDirectoryURL(
                    directoryName: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_NAME,
                    relativeTo: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH
                )
                
                guard let saveDestinationDirectoryURL = saveDestinationDirectoryURL else {
                    shouldDisableButtons = false

                    savingProgressStatus = .failed
                    
                    try await Task.sleep(milliseconds: 1200)
                    
                    shouldShowSavingProgressView = false
                    
                    return
                }
                
                let savedFileURL: URL? = try saveImageToSpecifiedDirectory(
                    ciImage: composedIDPhoto,
                    fileName: saveFileName,
                    fileType: saveFileUTType,
                    to: saveDestinationDirectoryURL
                )
                
                guard let savedFileURL = savedFileURL else {
                    shouldDisableButtons = false

                    savingProgressStatus = .failed
                    
                    try await Task.sleep(milliseconds: 1200)
                    
                    shouldShowSavingProgressView = false
                    
                    return
                }
                
                let imageFileNameWithPathExtension: String = savedFileURL.lastPathComponent
                
                var dateFormatterForExif: DateFormatter {
                    
                    let formatter: DateFormatter = .init()
                    
                    formatter.locale = NSLocale.system
                    formatter.dateFormat =  "yyyy:MM:dd HH:mm:ss"
                    
                    return formatter
                }
                
                let sourcePhotoProperties: [String: Any] = sourcePhotoCIImage.properties
                let sourcePhotoExif: [String: Any]? = sourcePhotoProperties[kCGImagePropertyExifDictionary as String] as? [String: Any]
                
                let sourcePhotoShotDateString: String? = sourcePhotoExif?[kCGImagePropertyExifDateTimeOriginal as String] as? String
                
                let sourcePhotoShotDate: Date? = dateFormatterForExif.date(from: sourcePhotoShotDateString ?? "")
                
                let sourcePhotoSaveDirectoryRootPath: FileManager.SearchPathDirectory = .libraryDirectory
                let sourcePhotoSaveDirectoryRelativePath: String = "SourcePhotos"
                
                let fileManager: FileManager = .default
                
                let sourcePhotoSaveDestinationURL: URL? = fetchOrCreateDirectoryURL(
                    directoryName: "SourcePhotos",
                    relativeTo: .libraryDirectory
                )
                
                guard let sourcePhotoSaveDestinationURL = sourcePhotoSaveDestinationURL else {
                    shouldDisableButtons = false

                    savingProgressStatus = .failed
                    
                    try await Task.sleep(milliseconds: 1200)
                    
                    shouldShowSavingProgressView = false
                    
                    return
                }
                
                let sourcePhotoPermanentURL: URL = sourcePhotoSaveDestinationURL
                    .appendingPathComponent(sourcePhotoTemporaryURL.lastPathComponent, conformingTo: .fileURL)
                
                try fileManager.copyItem(
                    at: sourcePhotoTemporaryURL,
                    to: sourcePhotoPermanentURL
                )
                
                let sourcePhotoSavedDirectory: SavedFilePath = .init(
                    on: viewContext,
                    rootSearchPathDirectory: sourcePhotoSaveDirectoryRootPath,
                    relativePathFromRootSearchPath: sourcePhotoSaveDirectoryRelativePath
                )
                
                let newSourcePhotoRecord: SourcePhoto = .init(
                    on: viewContext,
                    imageFileName: sourcePhotoTemporaryURL.lastPathComponent,
                    shotDate: sourcePhotoShotDate,
                    savedDirectory: sourcePhotoSavedDirectory
                )
                
                let newCreatedIDPhoto: CreatedIDPhoto = try registerCreatedIDPhotoRecord(
                    imageFileName: imageFileNameWithPathExtension,
                    saveDirectoryPath: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_NAME,
                    relativeTo: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH,
                    sourcePhotoRecord: newSourcePhotoRecord
                )
                
                savingProgressStatus = .succeeded
                
                try await Task.sleep(milliseconds: 1200)
                
                onDoneCreateIDPhotoProcessCallback?(newCreatedIDPhoto)
            } catch {
                shouldDisableButtons = false
                
                savingProgressStatus = .failed
                
                print(error)
            }
            
            try await Task.sleep(milliseconds: 1200)
            
            shouldShowSavingProgressView = false
        }
    }
    
    var body: some View {
        ZStack {
            if #available(iOS 16, *) {
                CreateIDPhotoView(
                    selectedProcess: $selectedProcess,
                    selectedBackgroundColor: $selectedBackgroundColor,
                    selectedBackgroundColorLabel: $selectedBackgroundColorLabel,
                    selectedIDPhotoSize: $selectedIDPhotoSizeVariant,
                    previewUIImage: $previewUIImage,
                    croppingCGRect: $croppingCGRect,
                    availableSizeVariants: availableIDPhotoSizeVariants
                )
                .onTapDismissButton {
                    showDiscardViewConfirmationDialog()
                }
                .onTapDoneButton(action: handleTapDoneButton)
                .toolbar(.hidden)
                .disabled(shouldDisableButtons)
            } else {
                CreateIDPhotoView(
                    selectedProcess: $selectedProcess,
                    selectedBackgroundColor: $selectedBackgroundColor,
                    selectedBackgroundColorLabel: $selectedBackgroundColorLabel,
                    selectedIDPhotoSize: $selectedIDPhotoSizeVariant,
                    previewUIImage: $previewUIImage,
                    croppingCGRect: $croppingCGRect,
                    availableSizeVariants: availableIDPhotoSizeVariants
                )
                .onTapDismissButton {
                    showDiscardViewConfirmationDialog()
                }
                .onTapDoneButton(action: handleTapDoneButton)
                .navigationBarHidden(true)
                .disabled(shouldDisableButtons)
            }
        }
        .statusBarHidden()
        .onReceive(Just(selectedBackgroundColor)) { newSelectedBackgroundColor in
            self.selectedBackgroundColorLabel = generateBackgroundColorLabel(newSelectedBackgroundColor)
        }
        .onReceive(
            Just(selectedBackgroundColor)
        ) { newSelectedBackgroundColor in
            Task {
                guard let sourcePhotoCIImage = sourcePhotoCIImage else { return }
                
                if selectedBackgroundColor == .clear {
                    Task { @MainActor in
                        self.previewUIImage = sourcePhotoCIImage.uiImage(orientation: sourceImageOrientation)
                    }
                    
                    return
                }
                
                let paintedPhoto: CIImage? = try await paintingImageBackgroundColor(sourceImage: sourcePhotoCIImage, backgroundColor: newSelectedBackgroundColor)
                
                guard let paintedPhotoUIImage: UIImage = paintedPhoto?.uiImage(orientation: self.sourceImageOrientation) else { return }
                
                Task { @MainActor in
                    self.previewUIImage = paintedPhotoUIImage
                }
            }
        }
        .onChange(of: selectedIDPhotoSizeVariant) { newVariant in
            guard let previewUIImage = previewUIImage else { return }
            
            Task {
                let generatedCroppingRect: CGRect = await generateCroppingRect(from: newVariant) ?? .init(origin: .zero, size: previewUIImage.size)
                
                if newVariant == .original {
                    Task { @MainActor in
                        self.croppingCGRect = .init(
                            origin: .zero,
                            size: previewUIImage.size
                        )
                    }
                    
                    return
                }
                
                Task { @MainActor in
                    self.croppingCGRect = generatedCroppingRect
                }
            }
        }
        .confirmationDialog(
            "証明写真作成を終了",
            isPresented: $shouldShowDiscardViewConfirmationDialog
        ) {
            Button(
                role: .destructive,
                action: {
                    
                    deleteTemporarySavedSourcePhotoFile()
                    
                    dismiss()
                }
            ) {
                Text("保存せずに終了")
            }
        }
        .overlay {
            ZStack {
                if shouldShowSavingProgressView {
                    Color.black
                        .opacity(0.3)
                        .environment(\.colorScheme, .dark)

                    SavingProgressView(
                        savingStatus: $savingProgressStatus
                    )
                    .frame(width: 40%.of(screenSizeHelper.screenSize.width))
                }
            }
            .edgesIgnoringSafeArea(.all)
            .animation(
                shouldShowSavingProgressView ? .none : .easeInOut,
                value: shouldShowSavingProgressView
            )
            .transition(.opacity)
        }
    }
}

extension CreateIDPhotoViewContainer {
    func registerCreatedIDPhotoRecord(
        imageFileName: String,
        saveDirectoryPath: String,
        relativeTo rootSearchPathDirectory: FileManager.SearchPathDirectory,
        sourcePhotoRecord: SourcePhoto
    ) throws -> CreatedIDPhoto {
        do {
            let appliedBackgroundColor: AppliedBackgroundColor = .init(
                on: viewContext,
                color: self.selectedBackgroundColor
            )
            
            let selectedIDPhotoSizeVariant: IDPhotoSizeVariant = self.selectedIDPhotoSizeVariant
            
            let appliedIDPhotoFaceHeight: AppliedIDPhotoFaceHeight = .init(
                on: viewContext,
                millimetersHeight: selectedIDPhotoSizeVariant.photoSize.faceHeight.value
            )
            
            let appliedMarginsAroundFace: AppliedMarginsAroundFace = .init(
                on: viewContext,
                bottom: selectedIDPhotoSizeVariant.photoSize.marginBottom?.value ?? -1,
                top: selectedIDPhotoSizeVariant.photoSize.marginTop.value
            )
            
            let appliedIDPhotoSize: AppliedIDPhotoSize = .init(
                on: viewContext,
                millimetersHeight: selectedIDPhotoSizeVariant.photoSize.height.value,
                millimetersWidth: selectedIDPhotoSizeVariant.photoSize.width.value,
                sizeVariant: selectedIDPhotoSizeVariant,
                faceHeight: appliedIDPhotoFaceHeight,
                marginsAroundFace: appliedMarginsAroundFace
            )
            
            let savedDirectory: SavedFilePath = .init(
                on: viewContext,
                rootSearchPathDirectory: rootSearchPathDirectory,
                relativePathFromRootSearchPath: saveDirectoryPath
            )
            
            let newCreatedIDPhotoRecord: CreatedIDPhoto = .init(
                on: viewContext,
                createdAt: .now,
                imageFileName: imageFileName,
                updatedAt: .now,
                appliedBackgroundColor: appliedBackgroundColor,
                appliedIDPhotoSize: appliedIDPhotoSize,
                savedDirectory: savedDirectory,
                sourcePhoto: sourcePhotoRecord
            )
            
            try viewContext.save()
            
            return newCreatedIDPhotoRecord
        } catch {
            throw error
        }
    }
    
    func deleteTemporarySavedSourcePhotoFile() -> Void {
        do {
            try FileManager.default.removeItem(at: sourcePhotoTemporaryURL)
        } catch {
            print(error)
        }
    }
}

extension CreateIDPhotoViewContainer {
    
    private func fetchOrCreateDirectoryURL(directoryName: String, relativeTo searchPathDirectory: FileManager.SearchPathDirectory) -> URL? {
        let fileManager: FileManager = .default
        
        let searchPathDirectoryURL: URL? = fileManager.urls(for: searchPathDirectory, in: .userDomainMask).first
        
        guard let searchPathDirectoryURL = searchPathDirectoryURL else { return nil }
        
        let targetDirectoryURL: URL = searchPathDirectoryURL
            .appendingPathComponent(directoryName, conformingTo: .directory)
        
        var objcTrue: ObjCBool = .init(true)
        
        let isTargetDirectoryExists: Bool = fileManager.fileExists(atPath: targetDirectoryURL.path, isDirectory: &objcTrue)
        
        if isTargetDirectoryExists {
            return targetDirectoryURL
        }
        
        do {
            try fileManager.createDirectory(at: targetDirectoryURL, withIntermediateDirectories: true)
            
            return targetDirectoryURL
        } catch {
            print(error)
            
            return nil
        }
    }
}

extension CreateIDPhotoViewContainer {
    
    func saveImageToSpecifiedDirectory(
        ciImage: CIImage,
        fileName: String,
        fileType: UTType,
        to saveDestinationDirectoryURL: URL
    ) throws -> URL? {
        
        let saveFilePathURL: URL = saveDestinationDirectoryURL
            .appendingPathComponent(fileName, conformingTo: fileType)
        
        let ciContext: CIContext = .init()
        
        do {
            if fileType == .jpeg {
                let jpegData: Data? = ciImage.jpegData(
                    ciContext: ciContext,
                    colorSpace: ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
                )
                
                guard let jpegData = jpegData else { return nil }
                
                try jpegData.write(to: saveFilePathURL)
                
                return saveFilePathURL
            }
            
            let heicData: Data? = ciImage.heifData(
                ciContext: ciContext,
                format: .RGBA8,
                colorSpace: ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            )
            
            guard let heicData = heicData else { return nil }
            
            try heicData.write(to: saveFilePathURL)
            
            return saveFilePathURL
        } catch {
            throw error
        }
    }
}

struct CreateIDPhotoViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUIImage: UIImage = UIImage(named: "PreviewSourceMaterialPhoto")!
        
        let sampleImageURL: URL = sampleUIImage.saveOnLibraryCachesForTest(fileName: "PreviewSourceMaterialPhoto")!
        
        let screenSizeHelper: ScreenSizeHelper = .shared
        
        NavigationView {
            GeometryReader { geometry in
                let screenSize: CGSize = geometry.size
                
                CreateIDPhotoViewContainer(
                    sourcePhotoURL: sampleImageURL
                )
                .environmentObject(screenSizeHelper)
                .onAppear {
                    screenSizeHelper.updateScreenSize(screenSize)
                }
                .onChange(of: screenSize) { newSize in
                    screenSizeHelper.updateScreenSize(newSize)
                }
            }
        }
    }
}
