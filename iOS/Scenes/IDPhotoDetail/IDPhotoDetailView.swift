//
//  IDPhotoDetailView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/02/23
//  
//

import SwiftUI

struct IDPhotoDetailView: View {
    @State var idPhotoSize: IDPhotoSize = {
        return IDPhotoSizeVariant.w24_h30.photoSize
    }()
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center, spacing: 20) {
                    Image("SampleIDPhoto")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    VStack(alignment: .center, spacing: 4) {
                        let photoWidth: Int = Int(idPhotoSize.width.value)
                        let photoHeight: Int = Int(idPhotoSize.height.value)
                        
                        let widthUnitSymbol: String = idPhotoSize.width.unit.symbol
                        let heightUnitSymbol: String = idPhotoSize.height.unit.symbol
                        
                        HStack(alignment: .center) {
                            Text("横 \(photoWidth) \(widthUnitSymbol)")
                                .fontWeight(.semibold)
                            
                            Image(systemName: "xmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 10)
                            
                            Text("縦 \(photoHeight) \(heightUnitSymbol)")
                                .fontWeight(.semibold)
                        }
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("作成日")
                            .font(.subheadline)
                            .foregroundColor(Color.secondaryLabel)
                        
                        HStack {
                            Text(Date(), style: .date)
                            
                            Text("(") + Text(Date(), style: .relative) + Text(" 前)")
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
        IDPhotoDetailView()
    }
}
