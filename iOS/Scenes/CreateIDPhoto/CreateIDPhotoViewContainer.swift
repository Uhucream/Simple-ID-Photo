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

struct SelectedSameValueAsPreviousError: Error {
    var localizedDescription: String {
        return "変更前と同じ選択肢が選択されました"
    }
}

struct CreateIDPhotoViewContainer: View {
    
    static let CREATED_ID_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH: FileManager.SearchPathDirectory = .libraryDirectory
    static let CREATED_ID_PHOTO_SAVE_FOLDER_NAME: String = "CreatedPhotos"
    
    static let DEFAULT_BACKGROUND_COLOR: Color = .idPhotoBackgroundColors.blue
    static let DEFAULT_SIZE_VARIANT: IDPhotoSizeVariant = .original
    
    @Environment(\.managedObjectContext) var viewContext
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject private var screenSizeHelper: ScreenSizeHelper
    
    private var sourcePhotoTemporaryURL: URL
    
    private var sourcePhotoCIImage: CIImage? {
        return .init(
            contentsOf: sourcePhotoTemporaryURL,
            options: [
                .applyOrientationProperty: true
            ]
        )
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
            sourceCIImage: self.sourcePhotoCIImage,
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
    
    private var selectedBackgroundColorLabel: String {
        return generateBackgroundColorLabel(self.selectedBackgroundColor)
    }
    
    @State private var originalSizePreviewUIImage: UIImage? = nil
    @State private var croppedPreviewUIImage: UIImage? = nil
    
    @State private var paintedPhotoCIImage: CIImage? = nil
    
    @State private var croppingCGRect: CGRect = .zero
    
    @State private var selectedProcess: IDPhotoProcessSelection = .backgroundColor
    
    @State private var selectedBackgroundColor: Color = CreateIDPhotoViewContainer.DEFAULT_BACKGROUND_COLOR
    @State private var selectedIDPhotoSizeVariant: IDPhotoSizeVariant = CreateIDPhotoViewContainer.DEFAULT_SIZE_VARIANT
    
    @State private var previousUserSelectedBackgroundColor: Color? = nil
    @State private var previousUserSelectedIDPhotoSizeVariant: IDPhotoSizeVariant? = nil
    
    @State private var shouldDisableButtons: Bool = false
    
    @State private var shouldShowBackgroundColorProgressView: Bool = false
    
    @State private var shouldShowSavingProgressView: Bool = false
    @State private var savingProgressStatus: SavingStatus = .inProgress
    
    @State private var shouldShowDiscardViewConfirmationDialog: Bool = false
    
    @State private var selectedBackgroundColorPublisher: PassthroughSubject<Color, Never> = .init()
    @State private var selectedIDPhotoSizeVariantPublisher: PassthroughSubject<IDPhotoSizeVariant, Never> = .init()
    
    private(set) var onDoneCreateIDPhotoProcessCallback: ((CreatedIDPhoto) -> Void)?
    
    init(sourcePhotoURL: URL) {
        
        self.sourcePhotoTemporaryURL = sourcePhotoURL
        
        _originalSizePreviewUIImage = State(initialValue: orientationFixedSourceUIImage)
        
        _croppedPreviewUIImage = State(initialValue: orientationFixedSourceUIImage)
        
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
        Task { @MainActor in
            self.shouldShowBackgroundColorProgressView = true
        }
        
        do {
            let solidColorBackgroundCIImage: CIImage = .init(
                color: CIColor(
                    cgColor: backgroundColor.cgColor ?? UIColor(backgroundColor).cgColor
                )
            ).cropped(to: CGRect(origin: .zero, size: sourceImage.extent.size))
            
            let generatedImage: CIImage? = try await visionFrameworkHelper.combineWithBackgroundImage(with: solidColorBackgroundCIImage)

            Task { @MainActor in
                self.shouldShowBackgroundColorProgressView = false
            }
            
            return generatedImage
        } catch {
            Task { @MainActor in
                self.shouldShowBackgroundColorProgressView = false
            }
            
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
                
                if croppingCGRect == .zero { return }
                
                guard let paintedPhotoCIImage = paintedPhotoCIImage else {
                    shouldDisableButtons = false

                    savingProgressStatus = .failed

                    try await Task.sleep(milliseconds: 1200)

                    shouldShowSavingProgressView = false

                    return
                }
                
                var dateFormatterForExif: DateFormatter {
                    
                    let formatter: DateFormatter = .init()
                    
                    formatter.locale = NSLocale.system
                    formatter.dateFormat =  "yyyy:MM:dd HH:mm:ss"
                    
                    return formatter
                }
                
                var exifModifiedPaintedPhotoCIImage: CIImage {
                    var paintedPhotoProperties: Dictionary<String, Any> = paintedPhotoCIImage.properties

                    var paintedPhotoExif: [String: Any]? = paintedPhotoProperties[kCGImagePropertyExifDictionary as String] as? [String: Any]
                    
                    guard var paintedPhotoExif = paintedPhotoExif else { return paintedPhotoCIImage }
                    
                    paintedPhotoExif[kCGImagePropertyExifDateTimeDigitized as String] = dateFormatterForExif.string(from: .now)
                    
                    paintedPhotoProperties[kCGImagePropertyExifDictionary as String] = paintedPhotoExif
                    
                    paintedPhotoProperties[kCGImagePropertyGPSDictionary as String] = nil
                    
                    let exifModifiedCIImage: CIImage = paintedPhotoCIImage.settingProperties(paintedPhotoProperties)
                    
                    return exifModifiedCIImage
                }
                
                let croppedPaintedPhotoCIImage: CIImage = exifModifiedPaintedPhotoCIImage.cropped(to: self.croppingCGRect)
                
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
                    ciImage: croppedPaintedPhotoCIImage,
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
                    selectedBackgroundColorLabel: .readOnly(self.selectedBackgroundColorLabel),
                    selectedIDPhotoSize: $selectedIDPhotoSizeVariant,
                    originalSizePreviewUIImage: $originalSizePreviewUIImage,
                    croppedPreviewUIImage: $croppedPreviewUIImage,
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
                    selectedBackgroundColorLabel: .readOnly(self.selectedBackgroundColorLabel),
                    selectedIDPhotoSize: $selectedIDPhotoSizeVariant,
                    originalSizePreviewUIImage: $originalSizePreviewUIImage,
                    croppedPreviewUIImage: $croppedPreviewUIImage,
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
        .onChange(of: self.selectedBackgroundColor) { newSelectedBackgroundColor in
            selectedBackgroundColorPublisher.send(newSelectedBackgroundColor)
        }
        .onChange(of: self.selectedIDPhotoSizeVariant) { newSelectedVariant in
            selectedIDPhotoSizeVariantPublisher.send(newSelectedVariant)
        }
        .onReceive(
            selectedBackgroundColorPublisher
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            //  MARK: http://web.archive.org/web/20230425043745/https://zenn.dev/ikuraikura/articles/2022-02-08-scan-pre#scan()を使う
                .scan(
                    (CreateIDPhotoViewContainer.DEFAULT_BACKGROUND_COLOR, CreateIDPhotoViewContainer.DEFAULT_BACKGROUND_COLOR)
                ) { previous, current in
                    return (previous.1, current)
                }
        ) { previousSelectedColor, _ in
            self.previousUserSelectedBackgroundColor = previousSelectedColor
        }
        .onReceive(
            selectedIDPhotoSizeVariantPublisher
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            //  MARK: http://web.archive.org/web/20230425043745/https://zenn.dev/ikuraikura/articles/2022-02-08-scan-pre#scan()を使う
                .scan(
                    (CreateIDPhotoViewContainer.DEFAULT_SIZE_VARIANT, CreateIDPhotoViewContainer.DEFAULT_SIZE_VARIANT)
                ) { previous, current in
                    return (previous.1, current)
                }
        ) { previousSelectedVariant, _ in
            self.previousUserSelectedIDPhotoSizeVariant = previousSelectedVariant
        }
        .task(id: selectedBackgroundColor) {
            do {
                try await Task.sleep(milliseconds: 500)

                if previousUserSelectedBackgroundColor == self.selectedBackgroundColor {
                    throw SelectedSameValueAsPreviousError()
                }
                
                guard let sourcePhotoCIImage = sourcePhotoCIImage else { return }
                
                if selectedBackgroundColor == .clear {
                    Task { @MainActor in
                        self.paintedPhotoCIImage = sourcePhotoCIImage
                    }
                    
                    guard let sourcePhotoUIImage: UIImage = sourcePhotoCIImage.uiImage(orientation: self.sourceImageOrientation) else { return }
                    
                    Task { @MainActor in
                        self.originalSizePreviewUIImage = sourcePhotoUIImage
                    }
                    
                    let croppedSourcePhotoCIImage: CIImage = sourcePhotoCIImage.cropped(to: croppingCGRect)
                    
                    let croppedSourcePhotoUIImage: UIImage? = croppedSourcePhotoCIImage.uiImage(orientation: self.sourceImageOrientation)
                    
                    Task { @MainActor in
                        self.croppedPreviewUIImage = croppedSourcePhotoUIImage
                    }
                    
                    return
                }
                
                let paintedPhoto: CIImage? = try await paintingImageBackgroundColor(
                    sourceImage: sourcePhotoCIImage,
                    backgroundColor: self.selectedBackgroundColor
                )
                
                guard let paintedPhoto = paintedPhoto else { return }
                
                Task { @MainActor in
                    self.paintedPhotoCIImage = paintedPhoto
                }
                
                if let paintedPhotoUIImage = paintedPhoto.uiImage(orientation: self.sourceImageOrientation) {
                    Task { @MainActor in
                        self.originalSizePreviewUIImage = paintedPhotoUIImage
                    }
                }
                
                let croppedPaintedPhotoCIImage: CIImage = paintedPhoto.cropped(to: croppingCGRect)
                
                guard let croppedPaintedPhotoUIImage: UIImage = croppedPaintedPhotoCIImage.uiImage(orientation: self.sourceImageOrientation) else { return }
                
                Task { @MainActor in
                    self.croppedPreviewUIImage = croppedPaintedPhotoUIImage
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        .task(id: selectedIDPhotoSizeVariant) {
            do {
                //  MARK: ユーザーが選択変更をやめてから処理を開始したいので、待つ
                try await Task.sleep(milliseconds: 500)

                if self.selectedIDPhotoSizeVariant == self.previousUserSelectedIDPhotoSizeVariant {
                    throw SelectedSameValueAsPreviousError()
                }
                
                guard let sourcePhotoCIImage = sourcePhotoCIImage else { return }
                
                if self.selectedIDPhotoSizeVariant == .original {
                    Task { @MainActor in
                        self.croppingCGRect = .init(
                            origin: .zero,
                            size: sourcePhotoCIImage.extent.size
                        )
                    }
                    
                    guard let paintedPhotoUIImage = self.paintedPhotoCIImage?.uiImage(orientation: self.sourceImageOrientation) else { return }
                    
                    Task { @MainActor in
                        self.croppedPreviewUIImage = paintedPhotoUIImage
                    }
                    
                    return
                }
                
                let generatedCroppingRect: CGRect? = await generateCroppingRect(
                    from: self.selectedIDPhotoSizeVariant
                )
                
                guard let generatedCroppingRect = generatedCroppingRect else { return }
                    
                Task { @MainActor in
                    self.croppingCGRect = generatedCroppingRect
                }
                
                let croppedPaintedPhotoCIImage: CIImage? = self.paintedPhotoCIImage?.cropped(to: generatedCroppingRect)
                
                guard let croppedPaintedPhotoUIImage: UIImage = croppedPaintedPhotoCIImage?.uiImage(orientation: self.sourceImageOrientation) else { return }
                
                Task { @MainActor in
                    self.croppedPreviewUIImage = croppedPaintedPhotoUIImage
                }
            } catch {
                print(error.localizedDescription)
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
        .overlay(alignment: .bottom) {
            Group {
                if shouldShowBackgroundColorProgressView {
                    HStack(alignment: .center, spacing: 4) {
                        ProgressView()
                        
                        Text("背景を合成中")
                    }
                    .padding(8)
                    .background(.black, in: Capsule())
                    .environment(\.colorScheme, .dark)
                    .offset(y: -20%.of(screenSizeHelper.screenSize.height))
                }
            }
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
