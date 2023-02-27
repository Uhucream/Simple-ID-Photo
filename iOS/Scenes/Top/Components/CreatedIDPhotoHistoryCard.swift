//
//  CreatedIDPhotoHistoryCard.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/02/26
//  
//

import SwiftUI

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
    
    var idPhotoThumbnailUIImage: UIImage
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
                    Image(uiImage: idPhotoThumbnailUIImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 50 * thumbnailScaleFactor, alignment: .top)
                        .clipped()
                        .shadow(radius: 0.8)
                    
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
                idPhotoThumbnailUIImage: mockHistory.createdUIImage,
                idPhotoSizeType: mockHistory.idPhotoSizeType,
                createdAt: mockHistory.createdAt
            )
            
            CreatedIDPhotoHistoryCard(
                idPhotoThumbnailUIImage: mockHistory.createdUIImage,
                idPhotoSizeType: .original,
                createdAt: mockHistory.createdAt
            )
            
            CreatedIDPhotoHistoryCard(
                idPhotoThumbnailUIImage: mockHistory.createdUIImage,
                idPhotoSizeType: .passport,
                createdAt: mockHistory.createdAt
            )
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Created ID Photo History Card")
    }
}
