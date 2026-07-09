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

    var sizeLabel: AppliedIDPhotoSizeLabel

    var idPhotoThumbnailImageURL: URL?

    var createdAt: Date

    init(
        sizeLabel: AppliedIDPhotoSizeLabel,
        idPhotoThumbnailImageURL: URL?,
        createdAt: Date
    ) {
        self.sizeLabel = sizeLabel

        self.idPhotoThumbnailImageURL = idPhotoThumbnailImageURL

        self.createdAt = createdAt
    }

    @ViewBuilder
    func renderTitle() -> some View {
        switch sizeLabel {

        case .original:
            Text("オリジナルサイズ")
                .fontWeight(.medium)

        case .passport:
            Text("パスポートサイズ")
                .fontWeight(.medium)

        case .millimeters(let width, let height):
            HStack(alignment: .center, spacing: 4 * titleScaleFactor) {
                Text("\(Int(width))")
                    .fontWeight(.medium)

                Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 8 * titleScaleFactor)

                Text("\(Int(height))")
                    .fontWeight(.medium)
            }

        case .unknown:
            Text("サイズ不明")
                .fontWeight(.medium)
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
                    let DEFAULT_THUMBNAIL_ASPECT_RATIO: CGFloat = 3 / 4

                    let createdIDPhotoAspectRatio: CGFloat = self.sizeLabel.aspectRatio ?? DEFAULT_THUMBNAIL_ASPECT_RATIO

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
            sizeSpecification: JapanIDPhotoSizes.w30h40,
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
                sizeLabel: .millimeters(width: 30, height: 40),
                idPhotoThumbnailImageURL: thumbnailURL,
                createdAt: mockHistory.createdAt
            )

            CreatedIDPhotoHistoryCard(
                sizeLabel: .original,
                idPhotoThumbnailImageURL: thumbnailURL,
                createdAt: mockHistory.createdAt
            )

            CreatedIDPhotoHistoryCard(
                sizeLabel: .passport,
                idPhotoThumbnailImageURL: thumbnailURL,
                createdAt: mockHistory.createdAt
            )
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Created ID Photo History Card")
    }
}
