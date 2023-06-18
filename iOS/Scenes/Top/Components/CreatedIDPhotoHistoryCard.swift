//
//  CreatedIDPhotoHistoryCard.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/02/26
//  
//

import SwiftUI
import Percentage

struct CreatedIDPhotoHistoryCard: View {
    static let numericDateStyle: Date.FormatStyle = {
        let style: Date.FormatStyle = .init(date: .numeric, time: .omitted)
        
        return style.month(.twoDigits).day(.twoDigits)
    }()
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @ScaledMetric(relativeTo: .callout) var titleScaleFactor: CGFloat = 1
    @ScaledMetric(relativeTo: .callout) var thumbnailScaleFactor: CGFloat = 1
    
    @ObservedObject var createdIDPhoto: CreatedIDPhoto

    var idPhotoSizeType: IDPhotoSizeVariant

    var idPhotoThumbnailImageURL: URL?
    
    var createdAt: Date
    
    init(
        createdIDPhoto: CreatedIDPhoto,
        idPhotoSizeType: IDPhotoSizeVariant,
        idPhotoThumbnailImageURL: URL?,
        createdAt: Date
    ) {
        _createdIDPhoto = .init(wrappedValue: createdIDPhoto)
        
        self.idPhotoSizeType = idPhotoSizeType

        self.idPhotoThumbnailImageURL = idPhotoThumbnailImageURL

        self.createdAt = createdAt
    }
    
    @ViewBuilder
    func renderTitle() -> some View {
        let photoWidth: Int = .init(idPhotoSizeType.photoSize.width.value)
        let photoHeight: Int = .init(idPhotoSizeType.photoSize.height.value)
        
        if self.idPhotoSizeType == .original {
            Text("オリジナルサイズ")
                .fontWeight(.medium)
        } else if self.idPhotoSizeType == .passport {
            Text("パスポートサイズ")
                .fontWeight(.medium)
        } else {
            HStack(alignment: .center, spacing: 4 * titleScaleFactor) {
                Text("\(photoWidth)")
                    .fontWeight(.medium)
                
                Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 8 * titleScaleFactor)
                
                Text("\(photoHeight)")
                    .fontWeight(.medium)
            }
        }
    }
    
    var body: some View {
        if self.dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading) {
                renderTitle()
                    .font(.callout)
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(createdAt, format: CreatedIDPhotoHistoryCard.numericDateStyle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(
                        createdAt,
                        format: .relative(
                            presentation: .numeric,
                            unitsStyle: .abbreviated
                        )
                    )
                    .font(.caption2)
                    .id(Int.random(in: 0...10)) // これがないと詳細画面から戻ったとき表示が更新されない
                }
                .foregroundColor(.secondaryLabel)
            }
        } else {
            HStack(alignment: .center) {

                HStack(alignment: .center, spacing: 12) {
                    let createdIDPhotoSize: IDPhotoSize = self.idPhotoSizeType.photoSize
                    
                    let createdIDPhotoAspectRatio: CGFloat = {
                        if self.idPhotoSizeType == .original || self.idPhotoSizeType == .custom {
                            return 3 / 4
                        }
                        
                        return createdIDPhotoSize.width.value / createdIDPhotoSize.height.value
                    }()
                    
                    let asyncImageContainerSideLength: CGFloat = 52 * thumbnailScaleFactor
                    
                    //  MARK: コンテナのサイズを正方形とする
                    let asyncImageContainerCGSize: CGSize = .init(
                        width: asyncImageContainerSideLength,
                        height: asyncImageContainerSideLength
                    )
                    
                    //  MARK: 読み込み中と読み込み後で高さが変わらないようにするため、ZStack をコンテナーとしてその中に AsyncImage を設置
                    ZStack {
                        AsyncImage(
                            url: idPhotoThumbnailImageURL
                        ) { asyncImagePhase in
                            
                            if case .success(let loadedImage) = asyncImagePhase {
                                GeometryReader { loadedImageGeometry in
                                    
                                    let loadedImageSize: CGSize = loadedImageGeometry.size
                                    
                                    let isPortraitImage: Bool = loadedImageSize.width < loadedImageSize.height
                                    
                                    loadedImage
                                        .resizable()
                                        .aspectRatio(contentMode: isPortraitImage ? .fill : .fit)
                                        .shadow(radius: 0.8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                }
                            }
                            
                            if case .empty = asyncImagePhase {
                                Rectangle()
                                    .fill(Color.clear)
                                    .aspectRatio(createdIDPhotoAspectRatio, contentMode: .fit)
                                    .overlay(.ultraThinMaterial)
                                    .overlay {
                                        ProgressView()
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    }
                            }
                            
                            if case .failure(let error) = asyncImagePhase {
                                Rectangle()
                                    .fill(Color.clear)
                                    .aspectRatio(createdIDPhotoAspectRatio, contentMode: .fit)
                                    .overlay(.ultraThinMaterial)
                                    .overlay {
                                        GeometryReader { geometry in
                                            Image(systemName: "questionmark.square.dashed")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.systemGray)
                                                .frame(width: 50%.of(geometry.size.width))
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                                .onAppear {
                                                    print(error)
                                                }
                                        }
                                    }
                            }
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: asyncImageContainerCGSize.width, height: asyncImageContainerCGSize.height, alignment: .center)
                    
                    renderTitle()
                        .font(.headline)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text("")
                        .font(.caption2)
                    
                    Text(createdAt, format: CreatedIDPhotoHistoryCard.numericDateStyle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    
                    Text(
                        createdAt,
                        format: .relative(
                            presentation: .numeric,
                            unitsStyle: .abbreviated
                        )
                    )
                    .font(.caption2)
                    .id(Int.random(in: 0...10)) // これがないと詳細画面から戻ったとき表示が更新されない
                }
                .foregroundColor(.secondaryLabel)
            }
        }
    }
}

struct CreatedIDPhotoHistoryCard_Previews: PreviewProvider {
    static var previews: some View {

        let mockHistory: CreatedIDPhotoDetail = .init(
            idPhotoSizeType: .w30_h40,
            createdAt: Calendar.current.date(byAdding: .year, value: -1, to: .now)!,
            createdUIImage: UIImage(named: "SampleIDPhoto")!
        )
        
        let mockCreatedIDPhoto: CreatedIDPhoto = .init(
            on: PersistenceController.preview.container.viewContext,
            createdAt: mockHistory.createdAt,
            imageFileName: "SampleIDPhoto.png",
            updatedAt: .now
        )
        
        let thumbnailURL: URL? = {
            let savedDirectoryURL: URL? = mockCreatedIDPhoto.savedDirectory?.parseToDirectoryFileURL()
            let fileName: String? = mockCreatedIDPhoto.imageFileName
            
            guard let savedDirectoryURL, let fileName else { return nil }
            
            let filePathURL: URL = savedDirectoryURL
                .appendingPathComponent(fileName, conformingTo: .fileURL)
            
            return filePathURL
        }()
        
        List {
            CreatedIDPhotoHistoryCard(
                createdIDPhoto: mockCreatedIDPhoto,
                idPhotoSizeType: mockHistory.idPhotoSizeType,
                idPhotoThumbnailImageURL: thumbnailURL,
                createdAt: mockHistory.createdAt
            )
            
            CreatedIDPhotoHistoryCard(
                createdIDPhoto: mockCreatedIDPhoto,
                idPhotoSizeType: .original,
                idPhotoThumbnailImageURL: thumbnailURL,
                createdAt: mockHistory.createdAt
            )
            
            CreatedIDPhotoHistoryCard(
                createdIDPhoto: mockCreatedIDPhoto,
                idPhotoSizeType: .passport,
                idPhotoThumbnailImageURL: thumbnailURL,
                createdAt: mockHistory.createdAt
            )
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Created ID Photo History Card")
    }
}
