//
//  IDPhotoDetailView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/02/23
//  
//

import SwiftUI

fileprivate let relativeDateTimeFormatter: RelativeDateTimeFormatter = {
    let formatter: RelativeDateTimeFormatter = .init()
    
    formatter.unitsStyle = .abbreviated
    
    return formatter
}()

struct IDPhotoDetailView: View {
    
    @Environment(\.colorScheme) var currentColorScheme
    
    @Binding var idPhotoUIImage: UIImage
    @Binding var idPhotoSizeType: IDPhotoSizeVariant
    
    @Binding var createdAt: Date
    
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
                    Image("SampleIDPhoto")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 250)
                        .background {
                            Rectangle()
                                .fill(currentColorScheme == .light ? Color.gray.opacity(0.2) : Color.fixedWhite.opacity(0.4))
                                .shadow(color: .black.opacity(0.5), radius: 8)
                                .blur(radius: 4)
                        }
                    
                    VStack(alignment: .center, spacing: 6) {
                        renderPhotoSizeLabel()
                            .lineLimit(1)
                        
                        Button(action: {
                            
                        }) {
                            Text("サイズを変更")
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(.init(top: .zero, leading: .zero, bottom: .zero, trailing: .zero))
            .listRowBackground(Color.systemGroupedBackground)
            
            Section {
                HStack {
                    Button(action: {
                        
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
            idPhotoUIImage: .constant(UIImage(named: "SampleIDPhoto")!),
            idPhotoSizeType: .constant(IDPhotoSizeVariant.w30_h40),
            createdAt: .constant(Calendar.current.date(byAdding: .month, value: -1, to: .now)!)
        )
    }
}
