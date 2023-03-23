//
//  CreatedIDPhotoHistoryCard.swift
//  Simple ID Photo (iOS)
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
    
    @ObservedObject var createdIDPhoto: CreatedIDPhoto
    
    @State private var createdAtRelativeLabel: String

    private var idPhotoThumbnailImageURL: URL? {
        return parseImageFileURL()
    }
    var idPhotoSizeType: IDPhotoSizeVariant
    
    var createdAt: Date
    
    init(
        createdIDPhoto: CreatedIDPhoto,
        idPhotoSizeType: IDPhotoSizeVariant,
        createdAt: Date
    ) {
        _createdIDPhoto = .init(wrappedValue: createdIDPhoto)
        
        _createdAtRelativeLabel = .init(
            initialValue: relativeDateTimeFormatter.localizedString(for: createdAt, relativeTo: .now)
        )
        
        self.idPhotoSizeType = idPhotoSizeType
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
    
    private func parseImageFileURL() -> URL? {
        let DEFAULT_SAVE_DIRECTORY_ROOT: FileManager.SearchPathDirectory = .libraryDirectory
        
        let LIBRARY_DIRECTORY_RAW_VALUE_INT64: Int64 = .init(DEFAULT_SAVE_DIRECTORY_ROOT.rawValue)
        
        let fileManager: FileManager = .default

        let saveDestinationRootSearchDirectory: FileManager.SearchPathDirectory = FileManager.SearchPathDirectory(rawValue: .init(createdIDPhoto.savedDirectory?.rootSearchPathDirectory ?? LIBRARY_DIRECTORY_RAW_VALUE_INT64)) ?? DEFAULT_SAVE_DIRECTORY_ROOT
        
        let saveDestinationRootSearchDirectoryURL: URL? = fileManager.urls(for: saveDestinationRootSearchDirectory, in: .userDomainMask).first
        
        let relativePathFromRoot: String = createdIDPhoto.savedDirectory?.relativePathFromRootSearchPath ?? ""
        let fileSaveDestinationURL: URL = .init(
            fileURLWithPath: relativePathFromRoot,
            isDirectory: true,
            relativeTo: saveDestinationRootSearchDirectoryURL
        )
        
        let createdIDPhotoFileName: String? = createdIDPhoto.imageFileName
        
        guard let createdIDPhotoFileName = createdIDPhotoFileName else { return nil }
        
        let createdIDPhotoFileURL: URL = fileSaveDestinationURL
            .appendingPathComponent(createdIDPhotoFileName, conformingTo: .fileURL)
        
        guard fileManager.fileExists(atPath: createdIDPhotoFileURL.path) else { return nil }
        
        return createdIDPhotoFileURL
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
                    
                    Text(createdAtRelativeLabel)
                        .font(.caption2)
                        .onAppear {
                            self.createdAtRelativeLabel = relativeDateTimeFormatter.localizedString(for: createdAt, relativeTo: .now)
                        }
                }
                .foregroundColor(.secondaryLabel)
            }
        } else {
            HStack(alignment: .center) {

                let createdIDPhotoSize: IDPhotoSize = self.idPhotoSizeType.photoSize
                
                let createdIDPhotoAspectRatio: CGFloat = {
                    if self.idPhotoSizeType == .original || self.idPhotoSizeType == .custom {
                        return 3 / 4
                    }
                    
                    return createdIDPhotoSize.width.value / createdIDPhotoSize.height.value
                }()
                
                let imageHeight: CGFloat = 48 * thumbnailScaleFactor
                
                AsyncImage(
                    url: idPhotoThumbnailImageURL
                ) { asyncImagePhase in
                    
                    if let loadedImage = asyncImagePhase.image {
                        
                        loadedImage
                            .resizable()
                            .shadow(radius: 0.8)
                            .scaledToFill()
                            .frame(width: imageHeight, height: imageHeight)
                        
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
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    }
                                }
                            }

                    }
                }
                .aspectRatio(1, contentMode: .fit)
                
                renderTitle()
                    .font(.callout)
                    .lineLimit(1)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text("")
                        .font(.caption2)
                    
                    Text(createdAt, formatter: dateFormatter)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(createdAtRelativeLabel)
                        .font(.caption2)
                        .onAppear {
                            self.createdAtRelativeLabel = relativeDateTimeFormatter.localizedString(for: createdAt, relativeTo: .now)
                        }
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
        
        List {
            CreatedIDPhotoHistoryCard(
                createdIDPhoto: mockCreatedIDPhoto,
                idPhotoSizeType: mockHistory.idPhotoSizeType,
                createdAt: mockHistory.createdAt
            )
            
            CreatedIDPhotoHistoryCard(
                createdIDPhoto: mockCreatedIDPhoto,
                idPhotoSizeType: .original,
                createdAt: mockHistory.createdAt
            )
            
            CreatedIDPhotoHistoryCard(
                createdIDPhoto: mockCreatedIDPhoto,
                idPhotoSizeType: .passport,
                createdAt: mockHistory.createdAt
            )
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Created ID Photo History Card")
    }
}
