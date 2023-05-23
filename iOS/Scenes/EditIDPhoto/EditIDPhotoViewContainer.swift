//
//  EditIDPhotoViewContainer.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/07
//  
//

import SwiftUI
import UIKit
import CoreData
import Combine
import UniformTypeIdentifiers
import Percentage

struct EditIDPhotoViewContainer: View {
    
    enum PhotoProcessInProgress: Hashable {
        case preparingPreview
        case backgroundColor
        
        var localizedMessage: String {
            switch self {
            case .preparingPreview:
                return "プレビューの準備中"
                
            case .backgroundColor:
                return "背景を合成中"
            }
        }
    }
    
    private let BACKGROUND_COLORS: [Color] = [
        .idPhotoBackgroundColors.blue,
        .idPhotoBackgroundColors.gray,
        .idPhotoBackgroundColors.white,
        .idPhotoBackgroundColors.brown
    ]
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var screenSizeHelper: ScreenSizeHelper
    
    @ObservedObject var editTargetCreatedIDPhoto: CreatedIDPhoto
    
    private var visionFrameworkHelper: VisionFrameworkHelper {
        
        let helper: VisionFrameworkHelper = .init(
            sourceCIImage: sourcePhotoCIImage,
            sourceImageOrientation: .init(self.sourceImageOrientation)
        )

        return helper
    }
    
    private var detectedFaceRect: CGRect {
        get async throws {
            try await detectFaceRect()
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
    
    @State private var originalCreatedIDPhotoFileURL: URL? = nil
    
    @State private var sourcePhotoFileURL: URL? = nil

    private var sourcePhotoCIImage: CIImage? {
        guard let sourcePhotoFileURL = sourcePhotoFileURL else { return nil }
        
        return .init(
            contentsOf: sourcePhotoFileURL,
            options: [
                .applyOrientationProperty: true
            ]
        )
    }
    
    private var sourceImageOrientation: UIImage.Orientation {
        guard let sourcePhotoFileURL = sourcePhotoFileURL else { return .up }
        
        let uiImageFromURL: UIImage = .init(url: sourcePhotoFileURL)
        let orientationFixedUIImage: UIImage? = uiImageFromURL.orientationFixed()

        return orientationFixedUIImage?.imageOrientation ?? .up
    }

    @State private var originalSizePreviewUIImage: UIImage? = nil
    @State private var croppedPreviewUIImage: UIImage? = nil
    
    @State private var paintedPhotoCIImage: CIImage? = nil
    
    @State private var croppingCGRect: CGRect = .null
    
    @State private var currentSelectedProcess: IDPhotoProcessSelection = .backgroundColor
    
    @State private var selectedBackgroundColor: Color = .idPhotoBackgroundColors.blue
    @State private var selectedIDPhotoSizeVariant: IDPhotoSizeVariant = .original

    @State private var previousUserSelectedBackgroundColor: Color? = nil
    @State private var previousUserSelectedIDPhotoSizeVariant: IDPhotoSizeVariant? = nil
    
    @State private var shouldDisableButtons: Bool = false
    
    @State private var photoProcessesInProgress: Set<PhotoProcessInProgress> = .init()
    
    @State private var shouldShowSavingProgressView: Bool = false
    @State private var savingProgressStatus: SavingStatus = .inProgress
    
    @State private var shouldShowDiscardViewConfirmationDialog: Bool = false
    
    //  MARK: レコード上に記録されている値から変わったかどうか
    @State private var isBackgroundColorModified: Bool = false
    @State private var isIDPhotoSizeVariantModified: Bool = false
    
    private var originalAppliedBackgroundColor: Color? {
        let appliedBackgroundColor: AppliedBackgroundColor? = editTargetCreatedIDPhoto.appliedBackgroundColor
        
        guard let appliedBackgroundColor = appliedBackgroundColor else { return nil }
        
        let colorFromEntity: Color = .init(
            red: appliedBackgroundColor.red,
            green: appliedBackgroundColor.green,
            blue: appliedBackgroundColor.blue,
            opacity: appliedBackgroundColor.alpha
        )
        
        return colorFromEntity
    }
    
    private var originalAppliedIDPhotoSizeVariant: IDPhotoSizeVariant? {
        let appliedIDPhotoSize: AppliedIDPhotoSize? = editTargetCreatedIDPhoto.appliedIDPhotoSize
        
        guard let appliedIDPhotoSize = appliedIDPhotoSize else { return nil }
        
        let appliedIDPhotoSizeVariant: IDPhotoSizeVariant? = .init(
            rawValue: Int(appliedIDPhotoSize.sizeVariant)
        )
        
        return appliedIDPhotoSizeVariant
    }

    private var hasAnyModifications: Bool {
        return isBackgroundColorModified || isIDPhotoSizeVariantModified
    }
    
    @State private var selectedBackgroundColorPublisher: PassthroughSubject<Color, Never> = .init()
    @State private var selectedIDPhotoSizeVariantPublisher: PassthroughSubject<IDPhotoSizeVariant, Never> = .init()
    
    //  MARK: 初回描画時から選択肢が変更されたかどうか
    @State private var isSelectionChanged: Bool = false
    
    private(set) var onDismissCallback: (() -> Void)?
    private(set) var onDoneSaveProcessCallback: (() -> Void)?
    
    init(
        initialDisplayProcess: IDPhotoProcessSelection,
        editTargetCreatedIDPhoto: CreatedIDPhoto
    ) {
        
        _editTargetCreatedIDPhoto = ObservedObject(wrappedValue: editTargetCreatedIDPhoto)
        
        _currentSelectedProcess = State(initialValue: initialDisplayProcess)
        
        if
            let sourcePhotoRecord = editTargetCreatedIDPhoto.sourcePhoto,
            let sourcePhotoFileName = sourcePhotoRecord.imageFileName,
            let sourcePhotoSavedFilePath = sourcePhotoRecord.savedDirectory
        {
            let sourcePhotoFileURL: URL? = self.parseSavedFileURL(
                fileName: sourcePhotoFileName,
                savedFilePath: sourcePhotoSavedFilePath
            )
            
            guard let sourcePhotoFileURL = sourcePhotoFileURL else { return }
            
            _sourcePhotoFileURL = State(initialValue: sourcePhotoFileURL)
        }

        if
            let createdIDPhotoFileName = editTargetCreatedIDPhoto.imageFileName,
            let createdIDPhotoSavedDirectory = editTargetCreatedIDPhoto.savedDirectory
        {

            let createdIDPhotoParsedURL: URL? = parseSavedFileURL(
                fileName: createdIDPhotoFileName,
                savedFilePath: createdIDPhotoSavedDirectory
            )
            
            guard let createdIDPhotoParsedURL = createdIDPhotoParsedURL else { return }
            
            _originalCreatedIDPhotoFileURL = State(initialValue: createdIDPhotoParsedURL)
            
            let createdIDPhotoUIImage: UIImage = .init(url: createdIDPhotoParsedURL)

            _croppedPreviewUIImage = .init(initialValue: createdIDPhotoUIImage)
        }
        
        let appliedBackgroundColor: AppliedBackgroundColor? = editTargetCreatedIDPhoto.appliedBackgroundColor
        let appliedIDPhotoSize: AppliedIDPhotoSize? = editTargetCreatedIDPhoto.appliedIDPhotoSize
        
        if let appliedBackgroundColor = appliedBackgroundColor {
            
            let colorFromEntity: Color = .init(
                red: appliedBackgroundColor.red,
                green: appliedBackgroundColor.green,
                blue: appliedBackgroundColor.blue,
                opacity: appliedBackgroundColor.alpha
            )
            
            _selectedBackgroundColor = State(initialValue: colorFromEntity)
        }
        
        if let appliedIDPhotoSize = appliedIDPhotoSize {
            
            let appliedIDPhotoSizeVariant: IDPhotoSizeVariant? = .init(
                rawValue: Int(appliedIDPhotoSize.sizeVariant)
            )
            
            guard let appliedIDPhotoSizeVariant = appliedIDPhotoSizeVariant else { return }
            
            _selectedIDPhotoSizeVariant = .init(initialValue: appliedIDPhotoSizeVariant)
        }
    }
    
    func onDismiss(action: @escaping () -> Void) -> Self {
        var view = self
        
        view.onDismissCallback = action
        
        return view
    }
    
    func onDoneSaveProcess(action: @escaping () -> Void) -> Self {
        var view = self
        
        view.onDoneSaveProcessCallback = action
        
        return view
    }
    
    func showDismissConfirmationDialog() -> Void {
        shouldShowDiscardViewConfirmationDialog = true
    }
    
    func detectFaceRect() async throws -> CGRect {
        do {
            let detectedRect: CGRect = try await visionFrameworkHelper.detectFaceIncludingHairRectangle()
            
            return detectedRect
        } catch {
            throw error
        }
    }
    
    func paintImageBackgroundColor(
        sourceImage: CIImage,
        backgroundColor: Color
    ) async throws -> CIImage? {
        do {
            let solidColorBackgroundCIImage: CIImage = .init(
                color: CIColor(
                    cgColor: backgroundColor.cgColor ?? UIColor(backgroundColor).cgColor
                )
            ).cropped(to: CGRect(origin: .zero, size: sourceImage.extent.size))
            
            let generatedImage: CIImage? = try await visionFrameworkHelper.combinedImage(with: solidColorBackgroundCIImage)
            
            return generatedImage
        } catch {
            throw error
        }
    }
    
    func generateCroppingRect(from sizeVariant: IDPhotoSizeVariant) async -> CGRect {

        guard let detectedFaceRect = try? await detectedFaceRect else { return .null }
        
        if detectedFaceRect == .null { return .null }
        
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
    
    //  TODO: パスポートサイズの対応
    //    func cropingImageAsPassportSize(sourceImage: CIImage) -> Void {
    //
    //    }
    
    func generateBackgroundColorLabel(_ color: Color) -> String {
        
        let colorRGBA: RGBAColorComponents? = color.rgba
        
        if
            let colorRGBA = colorRGBA,
            let clearRGBA = Color.clear.rgba,
            colorRGBA == clearRGBA
        {
            return "背景色なし"
        }
        
        if
            let colorRGBA = colorRGBA,
            let blueRGBA = Color.idPhotoBackgroundColors.blue.rgba,
            colorRGBA == blueRGBA
        {
            return "青"
        }
        
        if
            let colorRGBA = colorRGBA,
            let grayRGBA = Color.idPhotoBackgroundColors.gray.rgba,
            colorRGBA == grayRGBA
        {
            return "グレー"
        }
        
        if
            let colorRGBA = colorRGBA,
            let whiteRGBA = Color.idPhotoBackgroundColors.white.rgba,
            colorRGBA == whiteRGBA
        {
            return "白"
        }
        
        if
            let colorRGBA = colorRGBA,
            let brownRGBA = Color.idPhotoBackgroundColors.brown.rgba,
            colorRGBA == brownRGBA
        {
            return "茶"
        }
        
        return "不明"
    }
    
    var body: some View {
        EditIDPhotoView(
            selectedProcess: $currentSelectedProcess,
            selectedBackgroundColor: $selectedBackgroundColor,
            selectedBackgroundColorLabel: .readOnly(selectedBackgroundColorLabel),
            selectedIDPhotoSize: $selectedIDPhotoSizeVariant,
            originalSizePreviewUIImage: $originalSizePreviewUIImage,
            croppedPreviewUIImage: $croppedPreviewUIImage,
            croppingCGRect: $croppingCGRect,
            shouldDisableDoneButton: .readOnly(!hasAnyModifications),
            availableBackgroundColors: BACKGROUND_COLORS,
            availableSizeVariants: availableIDPhotoSizeVariants
        )
        .onTapDismissButton {
            if hasAnyModifications {
                showDismissConfirmationDialog()
                
                return
            }
            
            onDismissCallback?()
        }
        .onTapDoneButton {
            Task {
                Task { @MainActor in
                    self.shouldDisableButtons = true

                    self.shouldShowSavingProgressView = true
                }
                
                do {
                    
                    let fileManager: FileManager = .default
                    
                    guard let originalCreatedIDPhotoFileURL = self.originalCreatedIDPhotoFileURL else {
                        shouldDisableButtons = false

                        savingProgressStatus = .failed

                        try await Task.sleep(milliseconds: 1200)

                        shouldShowSavingProgressView = false

                        return
                    }
                    
                    let originalCreatedIDPhotoFileBaseName: String = originalCreatedIDPhotoFileURL
                        .deletingPathExtension()
                        .lastPathComponent
                    
                    let originalCreatedIDPhotoFileUTType: UTType? = UTType(filenameExtension: originalCreatedIDPhotoFileURL.pathExtension)
                    
                    guard let originalCreatedIDPhotoFileUTType = originalCreatedIDPhotoFileUTType else {
                        shouldDisableButtons = false

                        savingProgressStatus = .failed

                        try await Task.sleep(milliseconds: 1200)

                        shouldShowSavingProgressView = false

                        return
                    }
                    
                    guard let sourcePhotoCIImage = sourcePhotoCIImage else {
                        shouldDisableButtons = false

                        savingProgressStatus = .failed

                        try await Task.sleep(milliseconds: 1200)

                        shouldShowSavingProgressView = false

                        return
                    }
                    
                    guard let paintedPhotoCIImage = paintedPhotoCIImage else { return }
                    
                    let croppedPaintedIDPhoto: CIImage = paintedPhotoCIImage.cropped(to: self.croppingCGRect)
                    
                    let createdNewIDPhotoURL: URL?  = try createImageFile(
                        image: croppedPaintedIDPhoto,
                        fileName: originalCreatedIDPhotoFileBaseName,
                        fileType: originalCreatedIDPhotoFileUTType,
                        saveDestination: fileManager.temporaryDirectory
                    )
                    
                    guard let createdNewIDPhotoURL = createdNewIDPhotoURL else {
                        shouldDisableButtons = false

                        savingProgressStatus = .failed

                        try await Task.sleep(milliseconds: 1200)

                        shouldShowSavingProgressView = false

                        return
                    }
                    
                    try fileManager.replaceItemAt(originalCreatedIDPhotoFileURL, withItemAt: createdNewIDPhotoURL)
                    
                    let appliedColor: Color? = self.isBackgroundColorModified ? self.selectedBackgroundColor : nil
                    
                    let appliedSizeVariant: IDPhotoSizeVariant? = self.isIDPhotoSizeVariantModified ? self.selectedIDPhotoSizeVariant : nil
                    
                    try updateTargetCreatedIDPhotoRecord(
                        idPhotoBackgroundColor: appliedColor,
                        idPhotoSizeVariant: appliedSizeVariant,
                        idPhotoSize: appliedSizeVariant?.photoSize
                    )
                    
                    viewContext.refresh(self.editTargetCreatedIDPhoto, mergeChanges: true)
                    
                    savingProgressStatus = .succeeded
                    
                    try await Task.sleep(milliseconds: 1200)
                    
                    onDoneSaveProcessCallback?()
                } catch {
                    shouldDisableButtons = false
                    
                    savingProgressStatus = .failed
                    
                    print(error)
                }
                
                try await Task.sleep(milliseconds: 1200)
                
                shouldShowSavingProgressView = false
            }
        }
        .disabled(shouldDisableButtons)
        .statusBarHidden()
        .confirmationDialog(
            "編集を終了しますか？",
            isPresented: $shouldShowDiscardViewConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button(
                role: .destructive,
                action: {
                    onDismissCallback?()
                }
            ) {
                Text("編集を終了")
            }
        } message: {
            Text("加えた変更は保存されません")
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
                if self.photoProcessesInProgress.count > 0 {
                    LazyVStack {
                        ForEach(Array(photoProcessesInProgress), id: \.hashValue) { process in
                            LazyHStack(alignment: .center, spacing: 4) {
                                ProgressView()
                                
                                Text(process.localizedMessage)
                            }
                            .padding(8)
                            .background(.black, in: Capsule())
                            .animation(.easeOut, value: photoProcessesInProgress.count)
                            .environment(\.colorScheme, .dark)
                        }
                    }
                    .offset(y: -20%.of(screenSizeHelper.screenSize.height))
                }
            }
        }
        //  MARK: ProgressView が非表示になったあとに status をリセットする
        .onChange(of: shouldShowSavingProgressView) { newValue in
            guard newValue == false else { return }
            
            self.savingProgressStatus = .inProgress
        }
        .task(id: isSelectionChanged) {
            //  MARK: ユーザーが選択肢を変えたら処理をやめる
            //  https://stackoverflow.com/a/75399723/18698351
            if isSelectionChanged {
                Task { @MainActor in
                    self.photoProcessesInProgress.remove(.preparingPreview)
                }
                
                return
            }
            
            guard let sourcePhotoCIImage = sourcePhotoCIImage else { return }
            
            Task { @MainActor in
                self.photoProcessesInProgress.insert(.preparingPreview)
            }
            
            // MARK: 背景色処理 と croppingCGRect の処理の順番を逆にすると表示がおかしくなるので、この順番になっている
            // MARK: - 背景色が合成された画像の生成
            if self.selectedBackgroundColor == .clear {
                Task { @MainActor in
                    self.paintedPhotoCIImage = sourcePhotoCIImage
                }
                
                guard let sourcePhotoUIImage: UIImage = sourcePhotoCIImage.uiImage(orientation: self.sourceImageOrientation) else {
                    Task { @MainActor in
                        self.photoProcessesInProgress.remove(.preparingPreview)
                    }

                    return
                }
                
                Task { @MainActor in
                    self.originalSizePreviewUIImage = sourcePhotoUIImage
                }
            }
            
            if self.selectedBackgroundColor != .clear {
                async let paintedPhoto: CIImage? = paintImageBackgroundColor(
                    sourceImage: sourcePhotoCIImage,
                    backgroundColor: self.selectedBackgroundColor
                )
                
                guard let paintedPhoto = try? await paintedPhoto else {
                    Task { @MainActor in
                        self.photoProcessesInProgress.remove(.preparingPreview)
                    }

                    return
                }
                
                Task { @MainActor in
                    self.paintedPhotoCIImage = paintedPhoto
                }
                
                guard let paintedPhotoUIImage: UIImage = paintedPhoto.uiImage(orientation: self.sourceImageOrientation) else {
                    Task { @MainActor in
                        self.photoProcessesInProgress.remove(.preparingPreview)
                    }

                    return
                }
                
                Task { @MainActor in
                    self.originalSizePreviewUIImage = paintedPhotoUIImage
                }
            }
            
            // MARK: - croppingCGRect の生成
            if self.selectedIDPhotoSizeVariant == .original {
                Task { @MainActor in
                    self.croppingCGRect = .init(
                        origin: .zero,
                        size: sourcePhotoCIImage.extent.size
                    )
                }
            }

            if self.selectedIDPhotoSizeVariant != .original {
                async let generatedCroppingRect: CGRect? = await generateCroppingRect(from: self.selectedIDPhotoSizeVariant)

                guard let generatedCroppingRect = await generatedCroppingRect else {
                    Task { @MainActor in
                        self.photoProcessesInProgress.remove(.preparingPreview)
                    }

                    return
                }

                Task { @MainActor in
                    self.croppingCGRect = generatedCroppingRect
                }
            }
            
            Task { @MainActor in
                self.photoProcessesInProgress.remove(.preparingPreview)
            }
        }
        //  https://ondrej-kvasnovsky.medium.com/apply-textfield-changes-after-a-delay-debouncing-in-swiftui-af425446f8d8
        //  Just() に .debounce を書いても反応しないので、onChange を使用して変更を監視する
        .onChange(of: self.selectedBackgroundColor) { newSelectedBackgroundColor in
            selectedBackgroundColorPublisher.send(newSelectedBackgroundColor)
        }
        .onChange(of: self.selectedIDPhotoSizeVariant) { newSelectedVariant in
            selectedIDPhotoSizeVariantPublisher.send(newSelectedVariant)
        }
        .onChange(of: self.selectedBackgroundColor) { _ in
            guard self.isSelectionChanged == false else { return }

            self.isSelectionChanged = true
        }
        .onChange(of: self.selectedIDPhotoSizeVariant) { _ in
            guard self.isSelectionChanged == false else { return }

            self.isSelectionChanged = true
        }
        .onReceive(
            selectedIDPhotoSizeVariantPublisher
        ) { newIDPhotoSizeVariant in
            
            let DEFAULT_ID_PHOTO_SIZE_VARIANT: IDPhotoSizeVariant = .original
            let DEFAULT_ID_PHOTO_SIZE_VARIANT_INT32: Int32 = Int32(DEFAULT_ID_PHOTO_SIZE_VARIANT.rawValue)
            
            let currentAppliedIDPhotoSizeOnRecord: IDPhotoSizeVariant = .init(
                rawValue: Int(editTargetCreatedIDPhoto.appliedIDPhotoSize?.sizeVariant ?? DEFAULT_ID_PHOTO_SIZE_VARIANT_INT32)
            ) ?? DEFAULT_ID_PHOTO_SIZE_VARIANT
            
            let isIDPhotoSizeChanged: Bool = newIDPhotoSizeVariant != currentAppliedIDPhotoSizeOnRecord
            
            self.isIDPhotoSizeVariantModified = isIDPhotoSizeChanged
        }
        .onReceive(
            selectedBackgroundColorPublisher
        ) { newBackgroundColor in
            
            let originalBackgroundColorComponents: AppliedBackgroundColor? = editTargetCreatedIDPhoto.appliedBackgroundColor
            let newBackgroundColorComponents: RGBAColorComponents? = newBackgroundColor.rgba
            
            let isRedChanged: Bool = newBackgroundColorComponents?.red != CGFloat(originalBackgroundColorComponents?.red ?? 0)
            let isGreenChanged: Bool = newBackgroundColorComponents?.green != CGFloat(originalBackgroundColorComponents?.green ?? 0)
            let isBlueChanged: Bool = newBackgroundColorComponents?.blue != CGFloat(originalBackgroundColorComponents?.blue ?? 0)
            let isAlphaChanged: Bool = newBackgroundColorComponents?.alpha != CGFloat(originalBackgroundColorComponents?.alpha ?? 0)
            
            let isBackgroundColorChanged: Bool = isRedChanged || isGreenChanged || isBlueChanged || isAlphaChanged
            
            self.isBackgroundColorModified = isBackgroundColorChanged
        }
        .onReceive(
            selectedBackgroundColorPublisher
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            //  MARK: http://web.archive.org/web/20230425043745/https://zenn.dev/ikuraikura/articles/2022-02-08-scan-pre#scan()を使う
                .scan(
                    (self.originalAppliedBackgroundColor, self.originalAppliedBackgroundColor)
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
                    (self.originalAppliedIDPhotoSizeVariant, self.originalAppliedIDPhotoSizeVariant)
                ) { previous, current in
                    return (previous.1, current)
                }
        ) { previousSelectedVariant, _ in
            self.previousUserSelectedIDPhotoSizeVariant = previousSelectedVariant
        }
        .task(id: selectedBackgroundColor) {
            guard isSelectionChanged else { return }
            
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
                
                Task { @MainActor in
                    self.photoProcessesInProgress.insert(.backgroundColor)
                }
                
                let paintedPhoto: CIImage? = try await paintImageBackgroundColor(
                    sourceImage: sourcePhotoCIImage,
                    backgroundColor: self.selectedBackgroundColor
                )
                
                Task { @MainActor in
                    self.photoProcessesInProgress.remove(.backgroundColor)
                }

                guard let paintedPhoto = paintedPhoto else { return }
                
                Task { @MainActor in
                    self.paintedPhotoCIImage = paintedPhoto
                }
                
                if let paintedPhotoUIImage = paintedPhoto.uiImage(orientation: self.sourceImageOrientation) {
                    Task { @MainActor in
                        self.originalSizePreviewUIImage = paintedPhotoUIImage
                    }
                }
                
                //  MARK: .task(id: isSelectionChanged) 実行中に背景色の選択肢が変わってしまうと croppingCGRect.size が .zero のままになることがあるのでその対策
                if self.croppingCGRect.size == .zero {
                    if self.selectedIDPhotoSizeVariant == .original {
                        Task { @MainActor in
                            self.croppingCGRect = .init(
                                origin: .zero,
                                size: sourcePhotoCIImage.extent.size
                            )
                        }
                        
                        return
                    }
                    
                    async let generatedCroppingRect: CGRect? = generateCroppingRect(from: self.selectedIDPhotoSizeVariant)
                    
                    guard let generatedCroppingRect = await generatedCroppingRect else { return }
                    
                    Task { @MainActor in
                        self.croppingCGRect = generatedCroppingRect
                    }
                }
                
                let croppedPaintedPhotoCIImage: CIImage = paintedPhoto.cropped(to: croppingCGRect)
                
                guard let croppedPaintedPhotoUIImage: UIImage = croppedPaintedPhotoCIImage.uiImage(orientation: self.sourceImageOrientation) else { return }
                
                Task { @MainActor in
                    self.croppedPreviewUIImage = croppedPaintedPhotoUIImage
                }
            } catch {
                Task { @MainActor in
                    self.photoProcessesInProgress.remove(.backgroundColor)
                }
                
                print(error.localizedDescription)
            }
        }
        .task(id: selectedIDPhotoSizeVariant) {
            guard isSelectionChanged else { return }
            
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
    }
}

extension EditIDPhotoViewContainer {
    func parseSavedFileURL(
        fileName: String,
        savedFilePath: SavedFilePath
    ) -> URL? {
        
        let fileManager: FileManager = .default
        
        let parentDirectoryPathURL: URL? = savedFilePath.parseToDirectoryFileURL()
        
        guard let parentDirectoryPathURL = parentDirectoryPathURL else { return nil }
        
        let filePathURL: URL = parentDirectoryPathURL
            .appendingPathComponent(fileName, conformingTo: .fileURL)
        
        guard fileManager.fileExists(atPath: filePathURL.path) else { return nil }
        
        return filePathURL
    }
}

//  MARK: ファイル操作関連
extension EditIDPhotoViewContainer {
    
    func createImageFile(
        fileManager: FileManager = .default,
        image: CIImage,
        fileName: String,
        fileType: UTType,
        saveDestination: URL
    ) throws -> URL? {
        do {
            let ciContext: CIContext = .init()
            
            let filePathURL: URL = saveDestination
                .appendingPathComponent(fileName, conformingTo: fileType)
            
            if fileType == .jpeg {
                let jpegData: Data? = image.jpegData(
                    ciContext: ciContext,
                    colorSpace: image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
                )
                
                try jpegData?.write(to: filePathURL)
                
                return filePathURL
            }
            
            let heifData: Data? = image.heifData(
                ciContext: ciContext,
                format: .RGBA8,
                colorSpace: image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            )
            
            try heifData?.write(to: filePathURL)
            
            return filePathURL
        } catch {
            throw error
        }
    }
}

// MARK: Core Data 更新関連
extension EditIDPhotoViewContainer {
    func updateTargetCreatedIDPhotoRecord(
        idPhotoBackgroundColor: Color?,
        idPhotoSizeVariant: IDPhotoSizeVariant?,
        idPhotoSize: IDPhotoSize?
    ) throws -> Void {
        do {
            if idPhotoBackgroundColor == nil &&
                idPhotoSizeVariant == nil &&
                idPhotoSize == nil {
                return
            }
            
            if let appliedBackgroundColor = idPhotoBackgroundColor {
                editTargetCreatedIDPhoto.appliedBackgroundColor = .init(
                    on: viewContext,
                    color: appliedBackgroundColor
                )
            }
            
            if
                let appliedIDPhotoSizeVariant = idPhotoSizeVariant,
                let appliedIDPhotoSize = idPhotoSize
            {
                editTargetCreatedIDPhoto.appliedIDPhotoSize = .init(
                    on: viewContext,
                    millimetersHeight: appliedIDPhotoSize.height.value,
                    millimetersWidth: appliedIDPhotoSize.width.value,
                    sizeVariant: appliedIDPhotoSizeVariant
                )
            }
            
            editTargetCreatedIDPhoto.updatedAt = .now
            
            try viewContext.save()
        } catch {
            throw error
        }
    }
}

struct EditIDPhotoViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        
        let screenSizeHelper: ScreenSizeHelper = .shared
        
        let persistenceController: PersistenceController = .preview
        let viewContext: NSManagedObjectContext = persistenceController.container.viewContext
        
        let fetchRequestOfCreatedIDPhoto: NSFetchRequest<CreatedIDPhoto> = {
            let fetchRequest: NSFetchRequest<CreatedIDPhoto> = CreatedIDPhoto.fetchRequest()
            
            fetchRequest.fetchLimit = 1
            
            return fetchRequest
        }()
        
        let mockCreatedIDPhotoRecord: CreatedIDPhoto = {
            let createdIDPhoto: CreatedIDPhoto? = try? viewContext.fetch(fetchRequestOfCreatedIDPhoto).first
            
            if let createdIDPhoto = createdIDPhoto {
                return createdIDPhoto
            }
            
            let imageFileName: String = "SampleIDPhoto"
            
            let createdFileURL: URL? = UIImage(named: imageFileName)!.saveOnLibraryCachesForTest(fileName: imageFileName)
            
            let createdFileNameWithExtension: String? = createdFileURL?.lastPathComponent
            
            return .init(
                on: viewContext,
                createdAt: .distantPast,
                imageFileName: createdFileNameWithExtension,
                updatedAt: .now,
                savedDirectory: SavedFilePath(
                    on: viewContext,
                    rootSearchPathDirectory: .cachesDirectory,
                    relativePathFromRootSearchPath: ""
                )
            )
        }()
        
        GeometryReader { geometry in

            let screenSize: CGSize = geometry.size
            
            EditIDPhotoViewContainer(
                initialDisplayProcess: .backgroundColor,
                editTargetCreatedIDPhoto: mockCreatedIDPhotoRecord
            )
            .onAppear {
                screenSizeHelper.updateScreenSize(screenSize)
            }
            .onChange(of: screenSize) { newScreenSize in
                screenSizeHelper.updateScreenSize(newScreenSize)
            }
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(screenSizeHelper)
    }
}
