//
//  TopView_iOS16.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/17
//  
//

import SwiftUI
import UniformTypeIdentifiers
import GoogleMobileAds

@available(iOS 16, *)
struct TopView_iOS16<CreatedIDPhotosResults: RandomAccessCollection>: View where CreatedIDPhotosResults.Element ==  CreatedIDPhoto {
    enum DateSection: Int {
        case older = 0
        case newer = 1
    }
    
    @EnvironmentObject private var screenSizeHelper: ScreenSizeHelper
    
    @State private var isDroppingItemTargeted: Bool = false
    
    @Binding var shouldShowAdvertisement: Bool
    
    @Binding var nativeAdObject: NativeAd?
    
    @Binding var currentEditMode: EditMode
    
    var createdIDPhotoHistories: CreatedIDPhotosResults

    private var historiesSectionedByDate: [DateSection: [CreatedIDPhoto]] {
        createdIDPhotoHistories.reduce([DateSection: [CreatedIDPhoto]]()) { currentDictionary, createdIDPhoto in
            let createdAt: Date = createdIDPhoto.createdAt ?? .distantPast
            let startOfCreatedDate: Date = Calendar.gregorian.startOfDay(for: createdAt)
            
            let threeMonthsAgo: Date? = Calendar.gregorian.date(
                byAdding: .month,
                value: -3,
                to: Calendar.gregorian.startOfDay(for: .now)
            )
            let startOfThreeMonthsAgo: Date = Calendar.gregorian.date(
                from: Calendar.current.dateComponents(
                    [.year, .month],
                    from: threeMonthsAgo ?? .distantPast
                )
            ) ?? .distantPast
            
            let isDateWithinThreeMonths: Bool = startOfCreatedDate >= startOfThreeMonthsAgo
            
            let sectionForNewElement: DateSection = isDateWithinThreeMonths ? .newer : .older
            
            let newElement: [DateSection: [CreatedIDPhoto]] = [sectionForNewElement: [createdIDPhoto]]
            
            return currentDictionary.merging(newElement) { $0 + $1 }
        }
    }
    
    var dropAllowedFileUTTypes: [UTType]
    
    private let today: Date = Calendar.gregorian.startOfDay(for: .now)
    
    var onTapSelectFromAlbumButton: (() -> Void)?
    var onTapTakePictureButton: (() -> Void)?
    
    private(set) var onTapSaveImageButtonCallback: ((CreatedIDPhoto) -> Void)?
    
    private(set) var onDeleteHistoryCardCallback: (([CreatedIDPhoto]) -> Void)?
    
    private(set) var onDropFileCallback: (([NSItemProvider]) -> Bool)?
    
    @ViewBuilder
    func renderHistoryCard(_ createdIDPhotoHistory: CreatedIDPhoto) -> some View {
        
        let currentRenderingID: String = "\(createdIDPhotoHistory.id ?? .init())\(createdIDPhotoHistory.updatedAt ?? .now)"
        
        let thumbnailURL: URL? = {
            let savedDirectoryURL: URL? = createdIDPhotoHistory.savedDirectory?.parseToDirectoryFileURL()
            let fileName: String? = createdIDPhotoHistory.imageFileName
            
            guard let savedDirectoryURL, let fileName else { return nil }
            
            let filePathURL: URL = savedDirectoryURL
                .appendingPathComponent(fileName, conformingTo: .fileURL)
            
            return filePathURL
        }()
        
        CreatedIDPhotoHistoryCard(
            idPhotoSizeVariant: IDPhotoSizeVariant(rawValue: Int(createdIDPhotoHistory.appliedIDPhotoSize?.sizeVariant ?? 0)) ?? .custom,
            idPhotoThumbnailImageURL: thumbnailURL,
            createdAt: createdIDPhotoHistory.createdAt ?? .distantPast
        )
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
                        if historiesSectionedByDate.isEmpty {
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
                            ForEach(
                                Array(historiesSectionedByDate.keys).sorted { $0.rawValue > $1.rawValue },
                                id: \.rawValue
                            ) { section in
                                let historiesInSection = historiesSectionedByDate[section]
                                
                                if let historiesInSection, historiesInSection.count > 0 {
                                    let sortedHistoriesInSection = historiesInSection.sorted {
                                        ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
                                    }
                                    
                                    Section {
                                        ForEach(sortedHistoriesInSection) { history in
                                            NavigationLink(
                                                destination: IDPhotoDetailViewContainer(
                                                    createdIDPhoto: history
                                                )
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
                                        .onDelete { deleteTargetOffsets in
                                            let deleteTargetHistories: [CreatedIDPhoto] = deleteTargetOffsets.map { historiesInSection[$0] }
                                            
                                            onDeleteHistoryCardCallback?(deleteTargetHistories)
                                        }
                                    } header: {
                                        if section == .newer {
                                            Text("3ヶ月以内")
                                        } else {
                                            let newerSectionHistories: [CreatedIDPhoto] = historiesSectionedByDate[.newer] ?? []
                                            let doesNewerSectionExist: Bool = newerSectionHistories.count > 0
                                            
                                            Text(doesNewerSectionExist ? "それ以前" : "3ヶ月以上前")
                                        }
                                    }
                                }
                            }
                            
                            if let nativeAdObject = nativeAdObject, shouldShowAdvertisement {
                                Section {
                                    ListAdvertisementCard(
                                        nativeAd: nativeAdObject
                                    )
                                    .frame(minHeight: 80)
                                }
                                .listRowInsets(EdgeInsets())
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

@available(iOS 16, *)
struct TopView_iOS16_Previews: PreviewProvider {
    static var previews: some View {
        let screenSizeHelper: ScreenSizeHelper = .shared
        
        let viewContext = PersistenceController.preview.container.viewContext
        
        let adUnitID: String = {
            return Bundle.main.object(forInfoDictionaryKey: "AdMobListCellUnitID") as? String ?? ""
        }()
        
        let adLoadingHelper: NativeAdLoadingHelper = .init(advertisementUnitID: adUnitID)
        
        GeometryReader { geometry in
            TopView_iOS16(
                shouldShowAdvertisement: .constant(true),
                nativeAdObject: .readOnly(adLoadingHelper.nativeAd),
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
