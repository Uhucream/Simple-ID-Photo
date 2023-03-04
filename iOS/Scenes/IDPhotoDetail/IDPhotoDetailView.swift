//
//  IDPhotoDetailView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/02/23
//  
//

import SwiftUI
import Percentage

fileprivate let relativeDateTimeFormatter: RelativeDateTimeFormatter = {
    let formatter: RelativeDateTimeFormatter = .init()
    
    formatter.unitsStyle = .abbreviated
    
    return formatter
}()

struct IDPhotoDetailView: View {
    
    @Environment(\.colorScheme) var currentColorScheme
    
    @Binding var idPhotoImageURL: URL?
    @Binding var idPhotoSizeType: IDPhotoSizeVariant
    
    @Binding var createdAt: Date
    
    private(set) var onTapChangeSizeButtonCallback: (() -> Void)?
    
    private(set) var onTapPrintButtonCallback: (() -> Void)?
    private(set) var onTapSaveImageButtonCallback: (() -> Void)?
    
    public func onTapChangeSizeButton(action: @escaping () -> Void) -> Self {

        var view = self
        
        view.onTapChangeSizeButtonCallback = action
        
        return view
    }
    
    public func onTapPrintButton(action: @escaping () -> Void) -> Self {

        var view = self
        
        view.onTapPrintButtonCallback = action
        
        return view
    }
    
    public func onTapSaveImageButton(action: @escaping () -> Void) -> Self {

        var view = self
        
        view.onTapSaveImageButtonCallback = action
        
        return view
    }
    
    @ViewBuilder
    func renderPhotoSizeLabel() -> some View {
        
        if idPhotoSizeType == .original {
            Text("オリジナルサイズ")
                .fontWeight(.semibold)
        } else if self.idPhotoSizeType == .passport {
            Text("パスポートサイズ")
                .fontWeight(.semibold)
        } else {
            HStack(alignment: .center) {
                Text("横 \(projectGlobalMeasurementFormatter.string(from: idPhotoSizeType.photoSize.width))")
                    .fontWeight(.semibold)
                
                Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 10)
                
                Text("縦 \(projectGlobalMeasurementFormatter.string(from: idPhotoSizeType.photoSize.height))")
                    .fontWeight(.semibold)
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center, spacing: 28) {
                    
                    let createdIDPhotoSize: IDPhotoSize = self.idPhotoSizeType.photoSize
                    
                    let createdIDPhotoAspectRatio: CGFloat = {
                        if self.idPhotoSizeType == .original || self.idPhotoSizeType == .custom {
                            return 3 / 4
                        }
                        
                        return createdIDPhotoSize.width.value / createdIDPhotoSize.height.value
                    }()
                    
                    let imageMaxWidth: CGFloat = 250
                    
                    AsyncImage(
                        url: idPhotoImageURL
                    ) { asyncImagePhase in
                        if let loadedImage = asyncImagePhase.image {
                            loadedImage
                                .resizable()
                                .scaledToFit()
                                .background {
                                    Rectangle()
                                        .fill(currentColorScheme == .light ? Color.gray.opacity(0.2) : Color.fixedWhite.opacity(0.4))
                                        .shadow(color: .black.opacity(0.5), radius: 8)
                                        .blur(radius: 4)
                                }
                        } else {
                            Rectangle()
                                .fill(Color(uiColor: .systemFill))
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
                    .frame(maxWidth: imageMaxWidth)
                    
                    VStack(alignment: .center, spacing: 0) {
                        renderPhotoSizeLabel()
                            .font(.title3)
                            .lineLimit(1)
                        
                        Button(action: {
                            onTapChangeSizeButtonCallback?()
                        }) {
                            Text("サイズを変更")
                                .padding(4)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(.init(top: .zero, leading: .zero, bottom: .zero, trailing: .zero))
            .listRowBackground(Color.systemGroupedBackground)
            
            Section {
                HStack {
                    Button(action: {
                        onTapPrintButtonCallback?()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "printer")
                            
                            Text("印刷する")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: {
                        onTapSaveImageButtonCallback?()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "square.and.arrow.down")
                            
                            Text("保存する")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(.init(top: .zero, leading: .zero, bottom: .zero, trailing: .zero))
            .listRowBackground(Color.systemGroupedBackground)
            
            Section {
                Group {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("作成日")
                            .font(.subheadline)
                            .foregroundColor(Color.secondaryLabel)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Date(), style: .date)
                            
                            Text(relativeDateTimeFormatter.localizedString(for: Date().addingTimeInterval(-10000000), relativeTo: .now))
                                .font(.caption2)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .padding(.leading, 16)
            } header: {
                Text("詳細")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.label)
                    .padding(.vertical, 10)
            }
            .listRowInsets(.init(top: .zero, leading: .zero, bottom: .zero, trailing: .zero))
        }
    }
}

struct IDPhotoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        IDPhotoDetailView(
            idPhotoImageURL: .constant(
                mockHistoriesData[0].createdUIImage.localURLForXCAssets(fileName: "SampleIDPhoto")!
            ),
            idPhotoSizeType: .constant(IDPhotoSizeVariant.w30_h40),
            createdAt: .constant(Calendar.current.date(byAdding: .month, value: -1, to: .now)!)
        )
    }
}
