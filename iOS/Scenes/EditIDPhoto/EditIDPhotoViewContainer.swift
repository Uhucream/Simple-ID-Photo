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
import CoreImage
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

    private let availableBackgroundColors: [IDPhotoBackgroundColor] = IDPhotoBackgroundColor.presets

    private static let defaultSizeSpecification: any IDPhotoSizeSpecification = OriginalSizeSpecification.original

    //  w35xh45 は同寸法のパスポート規格 (規格の写り方) と誤認したユーザーが
    //  パスポート申請に使ってしまうのを防ぐため、パスポートサイズ対応が完了するまで表示しない
    private var availableSizeSpecifications: [any IDPhotoSizeSpecification] {
        var selectableSizes: [any IDPhotoSizeSpecification] = JapanIDPhotoSize.allCases.filter { $0 != .w35xh45 }

        //  廃止サイズを使っている写真では、その仕様書もこの写真の編集中だけ選べるようにする
        if
            let appliedSizeSpecification = originalAppliedSizeSpecification,
            let appliedMillimeterSize = appliedSizeSpecification.millimeterSize,
            selectableSizes.contains(where: { $0.id == appliedSizeSpecification.id }) == false
        {
            let insertionIndex: Int = selectableSizes.firstIndex {
                guard let millimeterSize = $0.millimeterSize else { return false }

                return millimeterSize > appliedMillimeterSize
            } ?? selectableSizes.endIndex

            selectableSizes.insert(appliedSizeSpecification, at: insertionIndex)
        }

        return [OriginalSizeSpecification.original] + selectableSizes
    }

    @Environment(\.managedObjectContext) private var viewContext

    @EnvironmentObject private var screenSizeHelper: ScreenSizeHelper

    @ObservedObject var editTargetCreatedIDPhoto: CreatedIDPhoto

    @State private var idPhotoEditor: IDPhotoEditor? = nil

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

    @State private var selectedBackgroundColor: IDPhotoBackgroundColor = .blue
    @State private var selectedSizeSpecification: any IDPhotoSizeSpecification = EditIDPhotoViewContainer.defaultSizeSpecification

    @State private var previousUserSelectedBackgroundColor: IDPhotoBackgroundColor? = nil
    @State private var previousUserSelectedSizeSpecification: (any IDPhotoSizeSpecification)? = nil

    @State private var shouldDisableButtons: Bool = false

    @State private var photoProcessesInProgress: Set<PhotoProcessInProgress> = .init()

    @State private var shouldShowSavingProgressView: Bool = false
    @State private var savingProgressStatus: SavingStatus = .inProgress

    @State private var shouldShowDiscardViewConfirmationDialog: Bool = false

    @State private var croppingErrorMessage: String? = nil
    @State private var shouldShowCroppingErrorAlert: Bool = false

    //  MARK: レコード上に記録されている値から変わったかどうか
    @State private var isBackgroundColorModified: Bool = false
    @State private var isSizeSpecificationModified: Bool = false

    private var originalAppliedBackgroundColor: IDPhotoBackgroundColor? {
        guard let appliedBackgroundColor = editTargetCreatedIDPhoto.appliedBackgroundColor else { return nil }

        return IDPhotoBackgroundColor(appliedBackgroundColor)
    }

    private var originalAppliedSizeSpecification: (any IDPhotoSizeSpecification)? {
        return editTargetCreatedIDPhoto.appliedIDPhotoSize?.resolvedSizeSpecification
    }

    private var hasAnyModifications: Bool {
        return isBackgroundColorModified || isSizeSpecificationModified
    }

    @State private var selectedBackgroundColorPublisher: PassthroughSubject<IDPhotoBackgroundColor, Never> = .init()
    @State private var selectedSizeSpecificationPublisher: PassthroughSubject<any IDPhotoSizeSpecification, Never> = .init()

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

            if let sourcePhotoFileURL = sourcePhotoFileURL {
                _sourcePhotoFileURL = State(initialValue: sourcePhotoFileURL)

                let sourcePhotoCIImage: CIImage? = .init(
                    contentsOf: sourcePhotoFileURL,
                    options: [
                        .applyOrientationProperty: true
                    ]
                )

                if let sourcePhotoCIImage = sourcePhotoCIImage {

                    let orientationFixedUIImage: UIImage? = UIImage(url: sourcePhotoFileURL).orientationFixed()
                    let sourceImageOrientation: UIImage.Orientation = orientationFixedUIImage?.imageOrientation ?? .up

                    //  保存済みの検出結果があれば注入し、Vision の再実行をスキップする
                    let precomputedSubject: IDPhotoSubject? = sourcePhotoRecord.detectedSubject.flatMap(IDPhotoSubject.init)

                    _idPhotoEditor = State(
                        initialValue: IDPhotoEditor(
                            sourceCIImage: sourcePhotoCIImage,
                            orientation: .init(sourceImageOrientation),
                            precomputedSubject: precomputedSubject
                        )
                    )
                }
            }
        }

        if
            let createdIDPhotoFileName = editTargetCreatedIDPhoto.imageFileName,
            let createdIDPhotoSavedDirectory = editTargetCreatedIDPhoto.savedDirectory
        {

            let createdIDPhotoParsedURL: URL? = parseSavedFileURL(
                fileName: createdIDPhotoFileName,
                savedFilePath: createdIDPhotoSavedDirectory
            )

            if let createdIDPhotoParsedURL = createdIDPhotoParsedURL {
                _originalCreatedIDPhotoFileURL = State(initialValue: createdIDPhotoParsedURL)

                let createdIDPhotoUIImage: UIImage = .init(url: createdIDPhotoParsedURL)

                _croppedPreviewUIImage = .init(initialValue: createdIDPhotoUIImage)
            }
        }

        if let appliedBackgroundColor = editTargetCreatedIDPhoto.appliedBackgroundColor {
            _selectedBackgroundColor = State(
                initialValue: IDPhotoBackgroundColor(appliedBackgroundColor)
            )
        }

        if let appliedIDPhotoSize = editTargetCreatedIDPhoto.appliedIDPhotoSize {

            //  廃止されたサイズなどで仕様書を解決できない場合はオリジナルとして扱う
            _selectedSizeSpecification = .init(
                initialValue: appliedIDPhotoSize.resolvedSizeSpecification ?? EditIDPhotoViewContainer.defaultSizeSpecification
            )
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

    var body: some View {
        EditIDPhotoView(
            selectedProcess: $currentSelectedProcess,
            selectedBackgroundColor: $selectedBackgroundColor,
            selectedBackgroundColorLabel: .readOnly(selectedBackgroundColor.label),
            selectedSizeSpecification: $selectedSizeSpecification,
            originalSizePreviewUIImage: $originalSizePreviewUIImage,
            croppedPreviewUIImage: $croppedPreviewUIImage,
            croppingCGRect: $croppingCGRect,
            shouldDisableDoneButton: .readOnly(!hasAnyModifications),
            availableBackgroundColors: availableBackgroundColors,
            availableSizeSpecifications: availableSizeSpecifications
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
                        colorSpace: sourcePhotoCIImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
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

                    let appliedBackgroundColor: IDPhotoBackgroundColor? = self.isBackgroundColorModified ? self.selectedBackgroundColor : nil

                    let appliedSizeSpecification: (any IDPhotoSizeSpecification)? = self.isSizeSpecificationModified ? self.selectedSizeSpecification : nil

                    //  検出済みの被写体情報が未保存なら保存する (v4 以前に作成されたレコードのアップグレード)
                    let detectedSubject: IDPhotoSubject? = await idPhotoEditor?.alreadyDetectedSubject()

                    try updateTargetCreatedIDPhotoRecord(
                        idPhotoBackgroundColor: appliedBackgroundColor,
                        idPhotoSizeSpecification: appliedSizeSpecification,
                        detectedSubject: detectedSubject
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
        .alert(
            "サイズを変更できません",
            isPresented: $shouldShowCroppingErrorAlert,
            presenting: croppingErrorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { croppingErrorMessage in
            Text(croppingErrorMessage)
        }
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

            guard let idPhotoEditor = idPhotoEditor else { return }

            Task { @MainActor in
                self.photoProcessesInProgress.insert(.preparingPreview)
            }

            do {
                // MARK: - 背景色が合成された画像の生成
                let paintedIDPhoto: IDPhoto = try await idPhotoEditor.painted(with: self.selectedBackgroundColor)

                Task { @MainActor in
                    self.paintedPhotoCIImage = paintedIDPhoto.ciImage
                }

                if let paintedPhotoUIImage = paintedIDPhoto.ciImage.uiImage(orientation: self.sourceImageOrientation) {
                    Task { @MainActor in
                        self.originalSizePreviewUIImage = paintedPhotoUIImage
                    }
                }

                // MARK: - croppingCGRect の生成
                let croppedIDPhoto: IDPhoto = try await idPhotoEditor.cropped(to: self.selectedSizeSpecification)

                if let generatedCroppingRect = croppedIDPhoto.appliedCroppingRect {
                    Task { @MainActor in
                        self.croppingCGRect = generatedCroppingRect
                    }
                }
            } catch {
                print(error.localizedDescription)
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
        .onChange(of: self.selectedSizeSpecification.id) { _ in
            selectedSizeSpecificationPublisher.send(self.selectedSizeSpecification)
        }
        .onChange(of: self.selectedBackgroundColor) { _ in
            guard self.isSelectionChanged == false else { return }

            self.isSelectionChanged = true
        }
        .onChange(of: self.selectedSizeSpecification.id) { _ in
            guard self.isSelectionChanged == false else { return }

            self.isSelectionChanged = true
        }
        .onReceive(
            selectedSizeSpecificationPublisher
        ) { newSizeSpecification in

            let currentAppliedSizeSpecificationID: String = self.originalAppliedSizeSpecification?.id ?? OriginalSizeSpecification.original.id

            let isSizeSpecificationChanged: Bool = newSizeSpecification.id != currentAppliedSizeSpecificationID

            self.isSizeSpecificationModified = isSizeSpecificationChanged
        }
        .onReceive(
            selectedBackgroundColorPublisher
        ) { newBackgroundColor in

            let currentAppliedBackgroundColor: IDPhotoBackgroundColor = self.originalAppliedBackgroundColor ?? .clear

            let isBackgroundColorChanged: Bool = newBackgroundColor != currentAppliedBackgroundColor

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
            selectedSizeSpecificationPublisher
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            //  MARK: http://web.archive.org/web/20230425043745/https://zenn.dev/ikuraikura/articles/2022-02-08-scan-pre#scan()を使う
                .scan(
                    (self.originalAppliedSizeSpecification, self.originalAppliedSizeSpecification)
                ) { previous, current in
                    return (previous.1, current)
                }
        ) { previousSelectedSpecification, _ in
            self.previousUserSelectedSizeSpecification = previousSelectedSpecification
        }
        .task(id: selectedBackgroundColor) {
            guard isSelectionChanged else { return }

            do {
                try await Task.sleep(milliseconds: 500)

                if previousUserSelectedBackgroundColor == self.selectedBackgroundColor {
                    throw SelectedSameValueAsPreviousError()
                }

                guard let idPhotoEditor = idPhotoEditor else { return }

                if self.selectedBackgroundColor != .clear {
                    Task { @MainActor in
                        self.photoProcessesInProgress.insert(.backgroundColor)
                    }
                }

                do {
                    let paintedIDPhoto: IDPhoto = try await idPhotoEditor.painted(with: self.selectedBackgroundColor)

                    Task { @MainActor in
                        self.photoProcessesInProgress.remove(.backgroundColor)
                    }

                    Task { @MainActor in
                        self.paintedPhotoCIImage = paintedIDPhoto.ciImage
                    }

                    if let paintedPhotoUIImage = paintedIDPhoto.ciImage.uiImage(orientation: self.sourceImageOrientation) {
                        Task { @MainActor in
                            self.originalSizePreviewUIImage = paintedPhotoUIImage
                        }
                    }

                    //  MARK: .task(id: isSelectionChanged) 実行中に背景色の選択肢が変わってしまうと croppingCGRect.size が .zero のままになることがあるのでその対策
                    if self.croppingCGRect.size == .zero {
                        let croppedIDPhoto: IDPhoto = try await idPhotoEditor.cropped(to: self.selectedSizeSpecification)

                        if let generatedCroppingRect = croppedIDPhoto.appliedCroppingRect {
                            Task { @MainActor in
                                self.croppingCGRect = generatedCroppingRect
                            }
                        }
                    }

                    let croppedPaintedPhotoCIImage: CIImage = paintedIDPhoto.ciImage.cropped(to: croppingCGRect)

                    guard let croppedPaintedPhotoUIImage: UIImage = croppedPaintedPhotoCIImage.uiImage(orientation: self.sourceImageOrientation) else { return }

                    Task { @MainActor in
                        self.croppedPreviewUIImage = croppedPaintedPhotoUIImage
                    }
                } catch {
                    Task { @MainActor in
                        self.photoProcessesInProgress.remove(.backgroundColor)
                    }

                    throw error
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        .task(id: selectedSizeSpecification.id) {
            guard isSelectionChanged else { return }

            do {
                //  MARK: ユーザーが選択変更をやめてから処理を開始したいので、待つ
                try await Task.sleep(milliseconds: 500)

                if self.selectedSizeSpecification.id == self.previousUserSelectedSizeSpecification?.id {
                    throw SelectedSameValueAsPreviousError()
                }

                guard let idPhotoEditor = idPhotoEditor else { return }

                let croppedIDPhoto: IDPhoto = try await idPhotoEditor.cropped(to: self.selectedSizeSpecification)

                if let generatedCroppingRect = croppedIDPhoto.appliedCroppingRect {
                    Task { @MainActor in
                        self.croppingCGRect = generatedCroppingRect
                    }
                }

                guard let croppedPhotoUIImage: UIImage = croppedIDPhoto.ciImage.uiImage(orientation: self.sourceImageOrientation) else { return }

                Task { @MainActor in
                    self.croppedPreviewUIImage = croppedPhotoUIImage
                }
            } catch let error as IDPhotoEditorError {
                Task { @MainActor in
                    self.croppingErrorMessage = error.localizedDescription
                    self.shouldShowCroppingErrorAlert = true

                    //  失敗した選択肢のままにしないため、直前の選択肢へ戻す
                    self.selectedSizeSpecification = self.previousUserSelectedSizeSpecification
                        ?? self.originalAppliedSizeSpecification
                        ?? EditIDPhotoViewContainer.defaultSizeSpecification
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
        colorSpace: CGColorSpace,
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
                    colorSpace: colorSpace
                )

                try jpegData?.write(to: filePathURL)

                return filePathURL
            }

            let heifData: Data? = image.heifData(
                ciContext: ciContext,
                format: .RGBA8,
                colorSpace: colorSpace
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
        idPhotoBackgroundColor: IDPhotoBackgroundColor?,
        idPhotoSizeSpecification: (any IDPhotoSizeSpecification)?,
        detectedSubject: IDPhotoSubject?
    ) throws -> Void {
        do {
            if let appliedBackgroundColor = idPhotoBackgroundColor {
                editTargetCreatedIDPhoto.appliedBackgroundColor = .init(
                    on: viewContext,
                    color: appliedBackgroundColor
                )
            }

            if let appliedSizeSpecification = idPhotoSizeSpecification {
                editTargetCreatedIDPhoto.appliedIDPhotoSize = .init(
                    on: viewContext,
                    sizeSpecification: appliedSizeSpecification
                )
            }

            //  v4 以前に作成されたレコードには検出結果が保存されていないため、このタイミングで保存する
            if
                let detectedSubject = detectedSubject,
                let sourcePhotoRecord = editTargetCreatedIDPhoto.sourcePhoto,
                sourcePhotoRecord.detectedSubject == nil
            {
                sourcePhotoRecord.detectedSubject = DetectedSubject(
                    on: viewContext,
                    subject: detectedSubject
                )
            }

            guard viewContext.hasChanges else { return }

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
