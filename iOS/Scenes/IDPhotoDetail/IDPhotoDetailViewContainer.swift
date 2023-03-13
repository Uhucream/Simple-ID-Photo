//
//  IDPhotoDetailViewContainer.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/01
//  
//

import SwiftUI
import Photos
import Percentage

enum SavingStatus {
    case inProgress
    case succeeded
    case failed
}

fileprivate struct SavingProgressView: View {
    
    @Binding var savingStatus: SavingStatus
    
    var body: some View {
        Group {
            GeometryReader { geometry in
                if savingStatus == .inProgress {
                    ProgressView("保存しています")
                        .foregroundColor(.label)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                
                if savingStatus == .succeeded {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 30%.of(geometry.size.height))
                        
                        Text("保存しました!")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                
                if savingStatus == .failed {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 30%.of(geometry.size.height))
                        
                        Text("失敗しました")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .font(.title3)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .aspectRatio(1, contentMode: .fit)
    }
}

struct IDPhotoDetailViewContainer: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var screenSizeHelper: ScreenSizeHelper
    
    @ObservedObject var createdIDPhoto: CreatedIDPhoto
    
    @State private var selectedIDPhotoProcess: IDPhotoProcessSelection? = nil
    
    @State private var shouldShowDeleteConfirmationDialog: Bool = false
    
    @State private var shouldShowChoosePrintMethodDialog: Bool = false
    
    @State private var shouldShowProgressView: Bool = false
    @State private var savingStatus: SavingStatus = .inProgress
    
    private func parseCreatedIDPhotoFileURL() -> URL? {
        let DEFAULT_SAVE_DIRECTORY_ROOT: FileManager.SearchPathDirectory = .libraryDirectory
        
        let LIBRARY_DIRECTORY_RAW_VALUE_INT64: Int64 = .init(DEFAULT_SAVE_DIRECTORY_ROOT.rawValue)
        
        let fileManager: FileManager = .default
        
        let fileSaveDestinationRootSearchDirectory: FileManager.SearchPathDirectory = .init(
            rawValue: UInt(
                self.createdIDPhoto.savedDirectory?.rootSearchPathDirectory ?? LIBRARY_DIRECTORY_RAW_VALUE_INT64
            )
        ) ?? DEFAULT_SAVE_DIRECTORY_ROOT
        
        let saveDestinationRootSearchDirectoryPathURL: URL? = fileManager.urls(
            for: fileSaveDestinationRootSearchDirectory,
            in: .userDomainMask
        ).first
        
        let relativePathFromRoot: String = createdIDPhoto.savedDirectory?.relativePathFromRootSearchPath ?? ""
        let fileSaveDestinationURL: URL = .init(
            fileURLWithPath: relativePathFromRoot,
            isDirectory: true,
            relativeTo: saveDestinationRootSearchDirectoryPathURL
        )
        
        let savedPhotoFileName: String? = createdIDPhoto.imageFileName
        
        guard let savedPhotoFileName = savedPhotoFileName else { return nil }
        
        let savedPhotoFileURL: URL = fileSaveDestinationURL
            .appendingPathComponent(savedPhotoFileName, conformingTo: .fileURL)
        
        guard fileManager.fileExists(atPath: savedPhotoFileURL.path) else { return nil }
        
        return savedPhotoFileURL
    }
    
    private func showEditIDPhotoView(initialDisplayProcess: IDPhotoProcessSelection) -> Void {
        self.selectedIDPhotoProcess = initialDisplayProcess
    }
    
    private func showDeleteConfirmationDialog() -> Void {
        self.shouldShowDeleteConfirmationDialog = true
    }
    
    private func showChoosePrintMethodDialog() -> Void {
        self.shouldShowChoosePrintMethodDialog = true
    }
    
    private func dismissEditIDPhotoView() -> Void {
        self.selectedIDPhotoProcess = nil
    }
    
    private func onTapDeleteButton() -> Void {
        do {
            let DEFAULT_SAVE_ROOT_SEARCH_PATH_DIRECTORY: FileManager.SearchPathDirectory = .libraryDirectory
            
            if let sourcePhotoRecord: SourcePhoto = createdIDPhoto.sourcePhoto {

                guard let sourcePhotoSavedDirectory: SavedFilePath = sourcePhotoRecord.savedDirectory else { return }
                
                let sourcePhotoSavedRootSearchPathDirectory: FileManager.SearchPathDirectory = .init(
                    rawValue: UInt(sourcePhotoSavedDirectory.rootSearchPathDirectory)
                ) ?? DEFAULT_SAVE_ROOT_SEARCH_PATH_DIRECTORY
                
                guard let sourcePhotoFileName: String = sourcePhotoRecord.imageFileName else { return }
                guard let relativePathFromRoot: String = sourcePhotoSavedDirectory.relativePathFromRootSearchPath else { return }
                
                try deleteSavedFile(
                    fileName: sourcePhotoFileName,
                    in: relativePathFromRoot,
                    relativeTo: sourcePhotoSavedRootSearchPathDirectory
                )
            }
            
            guard let createdIDPhotoSavedDirectory: SavedFilePath = createdIDPhoto.savedDirectory else { return }
            
            let createdIDPhotoSavedRootSearchPathDirectory: FileManager.SearchPathDirectory = .init(
                rawValue: UInt(createdIDPhotoSavedDirectory.rootSearchPathDirectory)
            ) ?? DEFAULT_SAVE_ROOT_SEARCH_PATH_DIRECTORY
            
            guard let createdIDPhotoFileName: String = createdIDPhoto.imageFileName else { return }
            guard let relativePathFromRoot: String = createdIDPhotoSavedDirectory.relativePathFromRootSearchPath else { return }
            
            try deleteSavedFile(
                fileName: createdIDPhotoFileName,
                in: relativePathFromRoot,
                relativeTo: createdIDPhotoSavedRootSearchPathDirectory
            )
            
            try deleteThisCreatedIDPhoto()
            
            dismiss()
        } catch {
            print(error)
        }
    }
    
    var body: some View {
        VStack {
            IDPhotoDetailView(
                idPhotoImageURL: Binding<URL?>(
                    get: {
                        return parseCreatedIDPhotoFileURL()
                    },
                    set: { (newImageURL) in
                        self.createdIDPhoto.imageFileName = newImageURL?.absoluteString
                    }
                ),
                idPhotoSizeType: Binding<IDPhotoSizeVariant>(
                    get: {
                        let appliedIDPhotoSize = createdIDPhoto.appliedIDPhotoSize
                        let idPhotoSizeVariant: IDPhotoSizeVariant = IDPhotoSizeVariant(rawValue: Int(appliedIDPhotoSize?.sizeVariant ?? 0)) ?? .original
                        
                        return idPhotoSizeVariant
                    },
                    set: { (newIDPhotoSizeVariant) in
                        createdIDPhoto.appliedIDPhotoSize?.sizeVariant = Int32(newIDPhotoSizeVariant.rawValue)
                    }
                ),
                createdAt: Binding<Date>(
                    get: {
                        let createdDate: Date = createdIDPhoto.createdAt ?? .distantPast
                        
                        return createdDate
                    },
                    set: { (newDate) in
                        createdIDPhoto.createdAt = newDate
                    }
                ),
                updatedAt: Binding<Date>(
                    get: {
                        return self.createdIDPhoto.updatedAt ?? .now
                    }, set: { _ in
                        
                    }
                )
            )
            .onTapChangeSizeButton {
                showEditIDPhotoView(initialDisplayProcess: .size)
            }
            .onTapPrintButton {
                showChoosePrintMethodDialog()
            }
            .onTapSaveImageButton {
                Task {
                    do {
                        self.shouldShowProgressView = true
                        
                        try await saveImageToCameraRoll()
                        
                        self.savingStatus = .succeeded
                        
                        try await Task.sleep(milliseconds: 1200)
                        
                        self.shouldShowProgressView = false
                    } catch {
                        
                        self.savingStatus = .failed
                        
                        try await Task.sleep(milliseconds: 1200)
                        
                        self.shouldShowProgressView = false
                        
                        print(error)
                    }
                }
            }
            .overlay {
                ZStack {
                    if shouldShowProgressView {
                        Color.black
                            .opacity(0.3)
                            .environment(\.colorScheme, .dark)

                        SavingProgressView(savingStatus: $savingStatus)
                            .frame(width: 40%.of(screenSizeHelper.screenSize.width), alignment: .center)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .edgesIgnoringSafeArea(.all)
                .animation(shouldShowProgressView ? .none : .easeOut, value: shouldShowProgressView)
                .transition(.opacity)
            }
            .confirmationDialog(
                "印刷方法を選択してください",
                isPresented: $shouldShowChoosePrintMethodDialog,
                titleVisibility: .visible
            ) {
                Button(
                    action: {
                        setupAndShowPrintInteractionController()
                    }
                ) {
                    Text("プリンターで印刷 (推奨)")
                }
                
                Button(
                    action: {
                        
                    }
                ) {
                    Text("コンビニで印刷")
                }
            }
            .confirmationDialog(
                "本当に削除しますか？",
                isPresented: $shouldShowDeleteConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button(
                    role: .destructive,
                    action: {
                        onTapDeleteButton()
                    }
                ) {
                    Text("削除する")
                }
            } message: {
                Text("削除した証明写真は復元できません")
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Button(
                            action: {
                                showEditIDPhotoView(initialDisplayProcess: .backgroundColor)
                            }
                        ) {
                            Label("背景色を変更", systemImage: "paintbrush")
                        }

                        Button(
                            action: {
                                showEditIDPhotoView(initialDisplayProcess: .size)
                            }
                        ) {
                            Label("サイズを変更", systemImage: "person.crop.rectangle")
                        }
                        
                        Divider()
                        
                        Button(
                            role: .destructive,
                            action: {
                                showDeleteConfirmationDialog()
                            }
                        ) {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fullScreenCover(item: $selectedIDPhotoProcess) { selectedProcess in
                EditIDPhotoViewContainer(
                    initialDisplayProcess: selectedProcess,
                    editTargetCreatedIDPhoto: self.createdIDPhoto
                )
                .onDismiss {
                    dismissEditIDPhotoView()
                }
                .onDoneSaveProcess {
                    dismissEditIDPhotoView()
                }
            }
        }
    }
}

extension IDPhotoDetailViewContainer {
    private func setupAndShowPrintInteractionController() -> Void {
        
        let appliedIDPhotoSize: AppliedIDPhotoSize? = createdIDPhoto.appliedIDPhotoSize
        
        let idPhotoMillimetersWidth: Double? = appliedIDPhotoSize?.millimetersWidth
        let idPhotoMillimetersHeight: Double? = appliedIDPhotoSize?.millimetersHeight
        
        guard
            let idPhotoMillimetersWidth = idPhotoMillimetersWidth,
            let idPhotoMillimetersHeight = idPhotoMillimetersHeight
        else { return }
        
        let printingIDPhotoActualSize: ActualSize = .init(
            width: .init(value: idPhotoMillimetersWidth, unit: .millimeters),
            height: .init(value: idPhotoMillimetersHeight, unit: .millimeters)
        )
        
        let printingIDPhotoCGSize: CGSize = printingIDPhotoActualSize.cgSize(pixelDensity: PrintPageRenderer.APPLE_PRINT_PIXEL_DENSITY)
        
        guard let createdIDPhotoFileURL: URL = parseCreatedIDPhotoFileURL() else { return }
        
        let printingIDPhotoUIImage: UIImage = .init(url: createdIDPhotoFileURL)
        
        let printingIDPhotoUIImageView: UIImageView = .init(image: printingIDPhotoUIImage)
        
        printingIDPhotoUIImageView.frame = .init(origin: .zero, size: printingIDPhotoCGSize)
        
        let printFormatter: UIViewPrintFormatter = printingIDPhotoUIImageView.viewPrintFormatter()
        
        let printPageRenderer: PrintPageRenderer = .init()
        
        printPageRenderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        
        printPageRenderer.onDrawPage = { (_, printableRect) in

            let idPhotoHorizontalPadding: CGFloat = (printableRect.width - printingIDPhotoCGSize.width) / 2
            let idPhotoVerticalPadding: CGFloat = (printableRect.height - printingIDPhotoCGSize.height) / 2

            //  printableRect のど真ん中に描画したいので、insetBy を使用して生成
            let idPhotoPrintAreaCGRect: CGRect = printableRect.insetBy(dx: idPhotoHorizontalPadding, dy: idPhotoVerticalPadding)

            printingIDPhotoUIImage.draw(in: idPhotoPrintAreaCGRect)
        }
        
        let printInfo: UIPrintInfo = .printInfo()
        
        printInfo.orientation = .portrait
        
        let printInteractionController: UIPrintInteractionController = .shared
        
        printInteractionController.showsPaperOrientation = false
        printInteractionController.showsNumberOfCopies = false
        printInteractionController.printInfo = printInfo
        printInteractionController.printPageRenderer = printPageRenderer
        
        printInteractionController.present(animated: true)
    }
}

extension IDPhotoDetailViewContainer {
    private func saveImageToCameraRoll() async throws -> Void {
        do {
            
            let createdIDPhotoFileURL: URL? = parseCreatedIDPhotoFileURL()
            
            guard let createdIDPhotoFileURL = createdIDPhotoFileURL else { return }
            
            let photoLibrary: PHPhotoLibrary = .shared()
            
            try await photoLibrary.performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: createdIDPhotoFileURL)
            })
        } catch {
            throw error
        }
    }
}

extension IDPhotoDetailViewContainer {
    private func deleteSavedFile(
        fileName: String,
        in relativeFilePathFromRoot: String,
        relativeTo rootSearchPathDirectory: FileManager.SearchPathDirectory,
        with fileManager: FileManager = .default
    ) throws -> Void {
        
        let fileSaveRootDirectoryURL: URL? = fileManager.urls(for: rootSearchPathDirectory, in: .userDomainMask).first
        
        let fileSaveDestinationURL: URL = .init(
            fileURLWithPath: relativeFilePathFromRoot,
            isDirectory: true,
            relativeTo: fileSaveRootDirectoryURL
        )
        
        let savedFilePathURL: URL = fileSaveDestinationURL
            .appendingPathComponent(fileName, conformingTo: .fileURL)
        
        guard fileManager.fileExists(atPath: savedFilePathURL.path) else { return }
        
        do {
            try fileManager.removeItem(at: savedFilePathURL)
        } catch {
            throw error
        }
    }
}

extension IDPhotoDetailViewContainer {
    func deleteThisCreatedIDPhoto() throws -> Void {
        do {
            viewContext.delete(self.createdIDPhoto)
            
            try viewContext.save()
        } catch {
            throw error
        }
    }
}

struct IDPhotoDetailViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            
            let mockCreatedIDPhoto: CreatedIDPhoto = .init(
                on: PersistenceController.preview.container.viewContext,
                createdAt: .now.addingTimeInterval(-1000),
                imageFileName: nil,
                updatedAt: .now
            )
            
            let screenSizeHelper: ScreenSizeHelper = .shared
            
            GeometryReader { geometry in
                
                let screenSize: CGSize = geometry.size
                
                IDPhotoDetailViewContainer(createdIDPhoto: mockCreatedIDPhoto)
                    .onAppear {
                        screenSizeHelper.updateScreenSize(screenSize)
                    }
                    .onChange(of: screenSize) { newSize in
                        screenSizeHelper.updateScreenSize(newSize)
                    }
                    .environmentObject(screenSizeHelper)
            }
        }
    }
}
