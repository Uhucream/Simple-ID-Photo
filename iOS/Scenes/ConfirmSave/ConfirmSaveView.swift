//
//  ConfirmSaveView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/02/10
//  
//

import SwiftUI

struct ConfirmSaveView: View {
    @Binding var previewImageForSavingUIImage: UIImage?
    
    var body: some View {
        Form {
            Section {
                Text("保存される画像には、L判用紙でそのまま印刷できるように、以下のように余白とガイド線がつきます")
                    .fontWeight(.bold)
            }
            .listRowInsets(.init(top: .zero, leading: .zero, bottom: .zero, trailing: .zero))
            .listRowBackground(Color.systemGroupedBackground)
            
            Section {
                if let savePreveiwUIImage = previewImageForSavingUIImage {
                    Image(uiImage: savePreveiwUIImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.systemGroupedBackground)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .overlay(.ultraThinMaterial)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .listRowBackground(Color.systemGroupedBackground)
        }
    }
}

struct ConfirmSaveView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmSaveView(
            previewImageForSavingUIImage: .constant(.init(named: "SampleIDPhoto")!)
        )
    }
}
