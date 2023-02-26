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

struct CreatedIDPhotoHistoryCard: View {
    
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
        } else {
            HStack(alignment: .center, spacing: 4) {
                Text("\(photoWidth)")
                    .fontWeight(.medium)
                
                Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 10)
                
                Text("\(photoHeight)")
                    .fontWeight(.medium)
            }
        }
    }
    
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(alignment: .center) {
                Image(uiImage: idPhotoThumbnailUIImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .shadow(radius: 0.8)
                
                renderTitle()
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                Text(createdAt, style: .date)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(relativeDateTimeFormatter.localizedString(for: createdAt, relativeTo: .now))
                    .font(.caption2)
            }
            .foregroundColor(.secondaryLabel)
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
            .frame(maxHeight: 40)
            
            CreatedIDPhotoHistoryCard(
                idPhotoThumbnailUIImage: mockHistory.createdUIImage,
                idPhotoSizeType: .original,
                createdAt: mockHistory.createdAt
            )
            .frame(maxHeight: 40)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Created ID Photo History Card")
    }
}
