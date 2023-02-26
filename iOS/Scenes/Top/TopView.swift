//
//  TopView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import SwiftUI

fileprivate let gregorianCalendar: Calendar = .init(identifier: .gregorian)

struct TopView: View {
    @EnvironmentObject private var screenSizeHelper: ScreenSizeHelper
    
    @Binding var createdIDPhotoHistories: [CreatedIDPhotoDetail]
    
    private let today: Date = gregorianCalendar.startOfDay(for: .now)
    
    var onTapSelectFromAlbumButton: (() -> Void)?
    var onTapTakePictureButton: (() -> Void)?
    
    @ViewBuilder
    func renderHistoryCard(_ createdIDPhotoHistory: CreatedIDPhotoDetail) -> some View {
        CreatedIDPhotoHistoryCard(
            idPhotoThumbnailUIImage: createdIDPhotoHistory.createdUIImage,
            idPhotoSizeType: createdIDPhotoHistory.idPhotoSizeType,
            createdAt: createdIDPhotoHistory.createdAt
        )
        .frame(maxHeight: 40)
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
                let historiesCreatedInThreeMonths: [CreatedIDPhotoDetail] = createdIDPhotoHistories
                    .filter { (history) -> Bool in
                        let startOfDateOfCreatedAt: Date = gregorianCalendar.startOfDay(for: history.createdAt)
                        
                        let elapsedMonths: Int = gregorianCalendar.dateComponents([.month], from: startOfDateOfCreatedAt, to: self.today).month!
                        
                        let isInThreeMonths = elapsedMonths <= 3
                        
                        return isInThreeMonths
                    }
                
                let historiesCreatedOverThreeMonthsAgo: [CreatedIDPhotoDetail] = createdIDPhotoHistories
                    .filter { (history) -> Bool in
                        let isHistoryContainedOnThreeMonthsHistories: Bool = historiesCreatedInThreeMonths.contains { historyInThreeMonths in
                            return gregorianCalendar.isDate(history.createdAt, inSameDayAs: historyInThreeMonths.createdAt)
                        }
                        
                        return !isHistoryContainedOnThreeMonthsHistories
                    }
                
                Section {
                    ForEach(historiesCreatedInThreeMonths) { history in
                        NavigationLink(destination: IDPhotoDetailView()) {
                            renderHistoryCard(history)
                        }
                        .isDetailLink(true)
                    }
                } header: {
                    Text("3ヶ月以内")
                }
                
                Section {
                    ForEach(historiesCreatedOverThreeMonthsAgo) { history in
                        NavigationLink(destination: IDPhotoDetailView()) {
                            renderHistoryCard(history)
                        }
                        .isDetailLink(true)
                    }
                } header: {
                    Text("それ以前")
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
        
        NavigationView {
            GeometryReader { geometry in
                TopView(
                    createdIDPhotoHistories: .constant(mockHistoriesData)
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
