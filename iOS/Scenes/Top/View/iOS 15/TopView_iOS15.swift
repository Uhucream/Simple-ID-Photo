//
//  TopView_iOS15.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/17
//  
//

import SwiftUI
import UniformTypeIdentifiers
import GoogleMobileAds

fileprivate let gregorianCalendar: Calendar = .init(identifier: .gregorian)

@available(iOS, introduced: 15, deprecated: 16)
struct TopView_iOS15<CreatedIDPhotosResults: RandomAccessCollection>: View where CreatedIDPhotosResults.Element ==  CreatedIDPhoto {
    
    @EnvironmentObject private var screenSizeHelper: ScreenSizeHelper
    
    @State private var isDroppingItemTargeted: Bool = false
    
    @Binding var nativeAdObject: GADNativeAd?
    
    @Binding var currentEditMode: EditMode
    
    var createdIDPhotoHistories: CreatedIDPhotosResults
    var dropAllowedFileUTTypes: [UTType]
    
    private let today: Date = gregorianCalendar.startOfDay(for: .now)
    
    var onTapSelectFromAlbumButton: (() -> Void)?
    var onTapTakePictureButton: (() -> Void)?
    
    private(set) var onTapSaveImageButtonCallback: ((CreatedIDPhoto) -> Void)?
    
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
        .frame(maxHeight: 60)
        .padding(.vertical, 4)
        .id(currentRenderingID)
    }
    
    func onDeleteHistoryCard(action: @escaping ([CreatedIDPhoto]) -> Void) -> Self {
        var view = self
        
        view.onDeleteHistoryCardCallback = action
        
        return view
    }
    
    func onTapSaveImageButton(action: @escaping (CreatedIDPhoto) -> Void) -> Self {
        var view = self
        
        view.onTapSaveImageButtonCallback = action
        
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
                if isDroppingItemTargeted {
                    Color.cyan
                        .opacity(0.8)
                        .overlay {
                            ZStack {
                                Rectangle()
                                    .stroke(
                                        Color.white,
                                        style: StrokeStyle(
                                            lineWidth: 4,
                                            lineCap: .round,
                                            lineJoin: .round,
                                            dash: [28, 28]
                                        )
                                    )
                                
                                Text("証明写真の元となる画像をドロップ")
                                    .font(.subheadline)
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .padding()
                        }
                        .opacity(0.8)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .listRowBackground(Color.systemGroupedBackground)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                } else {
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
                                
                                Section {
                                    ForEach(historiesWithinThreeMonths) { history in
                                        NavigationLink(
                                            destination: IDPhotoDetailViewContainer(createdIDPhoto: history)
                                        ) {
                                            renderHistoryCard(history)
                                        }
                                        .isDetailLink(true)
                                        .contextMenu {
                                            Button(
                                                action: {
                                                    onTapSaveImageButtonCallback?(history)
                                                }
                                            ) {
                                                Label("画像を保存", systemImage: "square.and.arrow.down")
                                            }
                                        }
                                    }
                                    .onDelete(perform: onDeleteForWithinThreeMonthsSection)
                                    .deleteDisabled(!currentEditMode.isEditing)
                                } header: {
                                    Text("3ヶ月以内")
                                }
                            }
                            
                            if let nativeAdObject = nativeAdObject {
                                Section {
                                    ListAdvertisementCard(
                                        nativeAd: .constant(nativeAdObject)
                                    )
                                    .frame(minHeight: 80)
                                }
                                .listRowInsets(EdgeInsets())
                            }
                            
                            if historiesOverThreeMonthsAgo.count > 0 {
                                
                                let onDeleteForOverThreeMonthsSection: (IndexSet) -> Void = { (deleteTargetsOffsets) in
                                    let deleteTargets: [CreatedIDPhoto] = deleteTargetsOffsets
                                        .map { deleteTargetOffset in
                                            return historiesOverThreeMonthsAgo[deleteTargetOffset]
                                        }
                                    
                                    self.onDeleteHistoryCardCallback?(deleteTargets)
                                }
                                
                                Section {
                                    ForEach(historiesOverThreeMonthsAgo) { history in
                                        NavigationLink(
                                            destination: IDPhotoDetailViewContainer(createdIDPhoto: history)
                                        ) {
                                            renderHistoryCard(history)
                                        }
                                        .isDetailLink(true)
                                        .contextMenu {
                                            Button(
                                                action: {
                                                    onTapSaveImageButtonCallback?(history)
                                                }
                                            ) {
                                                Label("画像を保存", systemImage: "square.and.arrow.down")
                                            }
                                        }
                                    }
                                    .onDelete(perform: onDeleteForOverThreeMonthsSection)
                                    .deleteDisabled(!currentEditMode.isEditing)
                                } header: {
                                    Text("それ以前")
                                }
                            }
                        }
                    }
                }
            }
            .onDrop(of: dropAllowedFileUTTypes, isTargeted: $isDroppingItemTargeted) { itemProviders in
                return onDropFileCallback?(itemProviders) ?? false
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("証明写真")
    }
}

@available(iOS, introduced: 15, deprecated: 16)
struct TopView_iOS15_Previews: PreviewProvider {
    static var previews: some View {
        let screenSizeHelper: ScreenSizeHelper = .shared
        
        let viewContext = PersistenceController.preview.container.viewContext
        
        let adUnitID: String = {
            return Bundle.main.object(forInfoDictionaryKey: "AdMobListCellUnitID") as? String ?? ""
        }()
        
        let adLoadingHelper: NativeAdLoadingHelper = .init(advertisementUnitID: adUnitID)
        
        GeometryReader { geometry in
            TopView_iOS15(
                nativeAdObject: Binding<GADNativeAd?>(
                    get: {
                        return adLoadingHelper.nativeAd
                    }, set: { _ in
                        
                    }
                ),
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
                screenSizeHelper.updateScreenSize(geometry.size)
                
                adLoadingHelper.refreshAd()
            }
            .onChange(of: geometry.safeAreaInsets) { (safeAreaInsets: EdgeInsets) in
                screenSizeHelper.updateSafeAreaInsets(safeAreaInsets)
            }
            .onChange(of: geometry.size) { (screenSize: CGSize) in
                screenSizeHelper.updateScreenSize(screenSize)
            }
        }
        .environmentObject(screenSizeHelper)
    }
}
