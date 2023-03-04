//
//  CreatedIDPhotoHistoryCard.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/02/26
//  
//

import SwiftUI
import Percentage

fileprivate let relativeDateTimeFormatter: RelativeDateTimeFormatter = {
    let formatter: RelativeDateTimeFormatter = .init()
    
    formatter.unitsStyle = .abbreviated
    
    return formatter
}()

fileprivate let dateFormatter: DateFormatter = {
    let formatter: DateFormatter = .init()
    
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    
    return formatter
}()

struct CreatedIDPhotoHistoryCard: View {
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @ScaledMetric(relativeTo: .callout) var titleScaleFactor: CGFloat = 1
    @ScaledMetric(relativeTo: .callout) var thumbnailScaleFactor: CGFloat = 1
    
    var idPhotoThumbnailImageURL: URL?
    var idPhotoSizeType: IDPhotoSizeVariant
    
    var createdAt: Date
    
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
                    Text(createdAt, formatter: dateFormatter)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(relativeDateTimeFormatter.localizedString(for: createdAt, relativeTo: .now))
                        .font(.caption2)
                }
                .foregroundColor(.secondaryLabel)
            }
        } else {
            HStack(alignment: .center) {
                HStack(alignment: .center) {

                    let createdIDPhotoSize: IDPhotoSize = self.idPhotoSizeType.photoSize
                    
                    let createdIDPhotoAspectRatio: CGFloat = {
                        if self.idPhotoSizeType == .original || self.idPhotoSizeType == .custom {
                            return 3 / 4
                        }
                        
                        return createdIDPhotoSize.width.value / createdIDPhotoSize.height.value
                    }()
                    
                    let imageMaxWidth: CGFloat = 50 * thumbnailScaleFactor
                    
                    AsyncImage(
                        url: idPhotoThumbnailImageURL
                    ) { asyncImagePhase in
                        
                        if let loadedImage = asyncImagePhase.image {
                            
                            loadedImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipped()
                                .shadow(radius: 0.8)
                            
                        } else {
                            
                            Rectangle()
                                .fill(Color.clear)
                                .aspectRatio(createdIDPhotoAspectRatio, contentMode: .fit)
                                .overlay(.ultraThinMaterial)
                                .overlay {
                                    Group {
                                        if let _ = asyncImagePhase.error {
                                            Image(systemName: "questionmark.square.dashed")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.systemGray)
                                        } else {
                                            ProgressView()
                                        }
                                    }
                                    .frame(maxWidth: 40%.of(imageMaxWidth))
                                }

                        }
                    }
                    .frame(maxWidth: imageMaxWidth, alignment: .top)
                    
                    renderTitle()
                        .font(.callout)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text("")
                        .font(.caption2)
                    
                    Text(createdAt, formatter: dateFormatter)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(relativeDateTimeFormatter.localizedString(for: createdAt, relativeTo: .now))
                        .font(.caption2)
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
        
        List {
            CreatedIDPhotoHistoryCard(
                idPhotoThumbnailImageURL: mockHistory.createdUIImage.localURLForXCAssets(fileName: "SampleIDPhoto")!,
                idPhotoSizeType: mockHistory.idPhotoSizeType,
                createdAt: mockHistory.createdAt
            )
            
            //  MARK: AsyncImage のクルクルの表示確認用
            CreatedIDPhotoHistoryCard(
                idPhotoThumbnailImageURL: nil,
                idPhotoSizeType: .original,
                createdAt: mockHistory.createdAt
            )
            
            //  MARK: AsyncImage の error の表示確認用
            CreatedIDPhotoHistoryCard(
                idPhotoThumbnailImageURL: .init(string: "hoge"),
                idPhotoSizeType: .passport,
                createdAt: mockHistory.createdAt
            )
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Created ID Photo History Card")
    }
}
