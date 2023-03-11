//
//  TopView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import SwiftUI
import UniformTypeIdentifiers

fileprivate let gregorianCalendar: Calendar = .init(identifier: .gregorian)

struct TopView<CreatedIDPhotosResults: RandomAccessCollection>: View where CreatedIDPhotosResults.Element ==  CreatedIDPhoto {
    
    @EnvironmentObject private var screenSizeHelper: ScreenSizeHelper
    
    @Binding var currentEditMode: EditMode
    
    var createdIDPhotoHistories: CreatedIDPhotosResults
    var dropAllowedFileUTTypes: [UTType]
    
    private let today: Date = gregorianCalendar.startOfDay(for: .now)
    
    var onTapSelectFromAlbumButton: (() -> Void)?
    var onTapTakePictureButton: (() -> Void)?
    
    private(set) var onDeleteHistoryCardCallback: (([CreatedIDPhoto]) -> Void)?
    
    private(set) var onDropFileCallback: (([NSItemProvider]) -> Bool)?
    
    @ViewBuilder
    func renderHistoryCard(_ createdIDPhotoHistory: CreatedIDPhoto) -> some View {
        
        let currentRenderingID: String = "\(createdIDPhotoHistory.id ?? .init())\(createdIDPhotoHistory.updatedAt ?? .now)"
        
        CreatedIDPhotoHistoryCard(
            createdIDPhoto: createdIDPhotoHistory,
            idPhotoSizeType: IDPhotoSizeVariant(rawValue: Int(createdIDPhotoHistory.appliedIDPhotoSize?.sizeVariant ?? 0)) ?? .custom,
            createdAt: createdIDPhotoHistory.createdAt ?? .distantPast
        )
        .id(currentRenderingID)
    }
    
    func onDeleteHistoryCard(action: @escaping ([CreatedIDPhoto]) -> Void) -> Self {
        var view = self
        
        view.onDeleteHistoryCardCallback = action
        
        return view
    }
    
    func onDropFile(action: @escaping ([NSItemProvider]) -> Bool) -> Self {
        var view = self
        
        view.onDropFileCallback = action
        
        return view
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Button(action: {
                        onTapSelectFromAlbumButton?()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "photo.on.rectangle.angled")
                            
                            Text("アルバムから選択")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .allowsTightening(true)
                                .fixedSize(horizontal: false, vertical: true)
                                .scaledToFit()
                        }
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.systemGray3)
                    .disabled(currentEditMode.isEditing)
                    
                    Button(action: {
                        onTapTakePictureButton?()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "camera")
                            
                            Text("カメラで撮影")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .allowsTightening(true)
                                .fixedSize(horizontal: false, vertical: true)
                                .scaledToFit()
                        }
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.cyan)
                    .disabled(currentEditMode.isEditing)
                }
                .padding(.vertical)
            }
            .listRowInsets(.init(top: .zero, leading: .zero, bottom: .zero, trailing: .zero))
            .listRowBackground(Color.systemGroupedBackground)
            
            Group {
                if createdIDPhotoHistories.count == 0 {
                    VStack(alignment: .center) {
                        Spacer()
                        
                        Text("作成された証明写真がありません")
                            .foregroundColor(.secondaryLabel)
                            .frame(maxWidth: .infinity)
                        
                        Spacer()
                    }
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .listRowBackground(Color.systemGroupedBackground)
                } else {
                    
                    let historiesWithinThreeMonths: [CreatedIDPhoto] = createdIDPhotoHistories
                        .filter { generatedIDPhoto in
                            let startOfShotDate: Date = gregorianCalendar.startOfDay(for: generatedIDPhoto.sourcePhoto?.shotDate ?? .distantPast)
                            
                            let elapsedMonths: Int = gregorianCalendar.dateComponents([.month], from: startOfShotDate, to: self.today).month!
                            
                            return elapsedMonths <= 3
                        }
                    
                    let historiesOverThreeMonthsAgo: [CreatedIDPhoto] = createdIDPhotoHistories
                        .filter { (history) -> Bool in
                            let isHistoryContainedOnThreeMonthsHistories: Bool = historiesWithinThreeMonths.contains(history)
                            
                            return !isHistoryContainedOnThreeMonthsHistories
                        }
                    
                    if historiesWithinThreeMonths.count > 0 {
                        
                        let onDeleteForWithinThreeMonthsSection: (IndexSet) -> Void = { (deleteTargetsOffsets) in
                            let deleteTargets: [CreatedIDPhoto] = deleteTargetsOffsets
                                .map { deleteTargetOffset in
                                    return historiesWithinThreeMonths[deleteTargetOffset]
                                }
                            
                            self.onDeleteHistoryCardCallback?(deleteTargets)
                        }
                        
                        //  MARK:  iOS 16 だと .deleteDisabled() の引数が動的な Bool の場合に常に無効化されてしまうので条件分岐
                        if #available(iOS 16, *) {
                            Section {
                                ForEach(historiesWithinThreeMonths) { history in
                                    NavigationLink(
                                        destination: IDPhotoDetailViewContainer(createdIDPhoto: history)
                                    ) {
                                        renderHistoryCard(history)
                                    }
                                    .isDetailLink(true)
                                }
                                .onDelete(perform: onDeleteForWithinThreeMonthsSection)
                            } header: {
                                Text("3ヶ月以内")
                            }
                        } else {
                            Section {
                                ForEach(historiesWithinThreeMonths) { history in
                                    NavigationLink(
                                        destination: IDPhotoDetailViewContainer(createdIDPhoto: history)
                                    ) {
                                        renderHistoryCard(history)
                                    }
                                    .isDetailLink(true)
                                }
                                .onDelete(perform: onDeleteForWithinThreeMonthsSection)
                                //  MARK: iOS 16 だと効かない
                                .deleteDisabled(!currentEditMode.isEditing)
                            } header: {
                                Text("3ヶ月以内")
                            }
                        }
                    }
                    
                    if historiesOverThreeMonthsAgo.count > 0 {
                        
                        let onDeleteForOverThreeMonthsSection: (IndexSet) -> Void = { (deleteTargetsOffsets) in
                            let deleteTargets: [CreatedIDPhoto] = deleteTargetsOffsets
                                .map { deleteTargetOffset in
                                    return historiesOverThreeMonthsAgo[deleteTargetOffset]
                                }
                            
                            self.onDeleteHistoryCardCallback?(deleteTargets)
                        }
                        
                        //  MARK:  iOS 16 だと .deleteDisabled() の引数が動的な Bool の場合に常に無効化されてしまうので条件分岐
                        if #available(iOS 16, *) {
                            Section {
                                ForEach(historiesOverThreeMonthsAgo) { history in
                                    NavigationLink(
                                        destination: IDPhotoDetailViewContainer(createdIDPhoto: history)
                                    ) {
                                        renderHistoryCard(history)
                                    }
                                    .isDetailLink(true)
                                }
                                .onDelete(perform: onDeleteForOverThreeMonthsSection)
                            } header: {
                                Text("それ以前")
                            }
                        } else {
                            Section {
                                ForEach(historiesOverThreeMonthsAgo) { history in
                                    NavigationLink(
                                        destination: IDPhotoDetailViewContainer(createdIDPhoto: history)
                                    ) {
                                        renderHistoryCard(history)
                                    }
                                    .isDetailLink(true)
                                }
                                .onDelete(perform: onDeleteForOverThreeMonthsSection)
                                //  MARK: iOS 16 だと効かない
                                .deleteDisabled(!currentEditMode.isEditing)
                            } header: {
                                Text("それ以前")
                            }
                        }
                    }
                }
            }
            .onDrop(of: dropAllowedFileUTTypes, isTargeted: .constant(false)) { itemProviders in
                return onDropFileCallback?(itemProviders) ?? false
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("証明写真")
    }
}

struct TopView_Previews: PreviewProvider {
    static var previews: some View {
        let screenSizeHelper: ScreenSizeHelper = .shared
        
        let viewContext = PersistenceController.preview.container.viewContext
        
        NavigationView {
            GeometryReader { geometry in
                TopView(
                    currentEditMode: .constant(.inactive),
                    createdIDPhotoHistories: [
                        .init(
                            on: viewContext,
                            createdAt: .distantPast,
                            imageFileName: mockHistoriesData[3].createdUIImage.saveOnLibraryCachesForTest(fileName: "SampleIDPhoto")!.absoluteString,
                            updatedAt: .now
                        ),
                        .init(
                            on: viewContext,
                            createdAt: .distantPast,
                            imageFileName: "",
                            updatedAt: .now
                        )
                    ],
                    dropAllowedFileUTTypes: [.image]
                )
                .onAppear {
                    screenSizeHelper.updateSafeAreaInsets(geometry.safeAreaInsets)
                    screenSizeHelper.updateScreenSize(screenWidth: geometry.size.width, screenHeight: geometry.size.height)
                }
                .onChange(of: geometry.safeAreaInsets) { (safeAreaInsets: EdgeInsets) in
                    screenSizeHelper.updateSafeAreaInsets(safeAreaInsets)
                }
                .onChange(of: geometry.size) { (screenSize: CGSize) in
                    screenSizeHelper.updateScreenSize(screenWidth: screenSize.width, screenHeight: screenSize.height)
                }
            }
            .environmentObject(screenSizeHelper)
        }
    }
}
