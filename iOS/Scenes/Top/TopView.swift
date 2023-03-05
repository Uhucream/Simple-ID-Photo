//
//  TopView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import SwiftUI

fileprivate let gregorianCalendar: Calendar = .init(identifier: .gregorian)

struct TopView<CreatedIDPhotosResults: RandomAccessCollection>: View where CreatedIDPhotosResults.Element ==  CreatedIDPhoto {

    @EnvironmentObject private var screenSizeHelper: ScreenSizeHelper
    
    var createdIDPhotoHistories: CreatedIDPhotosResults
    
    private let today: Date = gregorianCalendar.startOfDay(for: .now)
    
    var onTapSelectFromAlbumButton: (() -> Void)?
    var onTapTakePictureButton: (() -> Void)?
    
    @ViewBuilder
    func renderHistoryCard(_ createdIDPhotoHistory: CreatedIDPhoto) -> some View {
        CreatedIDPhotoHistoryCard(
            idPhotoThumbnailImageURL: URL(string: createdIDPhotoHistory.imageFileName ?? ""),
            idPhotoSizeType: IDPhotoSizeVariant(rawValue: Int(createdIDPhotoHistory.appliedIDPhotoSize?.sizeVariant ?? 0)) ?? .custom,
            createdAt: createdIDPhotoHistory.createdAt ?? .distantPast
        )
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
                }
                .padding(.vertical)
            }
            .listRowInsets(.init(top: .zero, leading: .zero, bottom: .zero, trailing: .zero))
            .listRowBackground(Color.systemGroupedBackground)
            
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
                    Section {
                        ForEach(historiesWithinThreeMonths) { history in
                            NavigationLink(
                                destination: IDPhotoDetailViewContainer(createdIDPhoto: history)
                            ) {
                                renderHistoryCard(history)
                            }
                            .isDetailLink(true)
                        }
                    } header: {
                        Text("3ヶ月以内")
                    }
                }
                
                if historiesOverThreeMonthsAgo.count > 0 {
                    Section {
                        ForEach(historiesOverThreeMonthsAgo) { history in
                            NavigationLink(
                                destination: IDPhotoDetailViewContainer(createdIDPhoto: history)
                            ) {
                                renderHistoryCard(history)
                            }
                            .isDetailLink(true)
                        }
                    } header: {
                        Text("それ以前")
                    }
                }

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
                    ]
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
