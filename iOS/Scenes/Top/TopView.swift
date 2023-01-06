//
//  TopView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import SwiftUI

struct TopView: View {
    var body: some View {
        Group {
            VStack {
                Spacer()
                
                Text("作成された証明写真がありません")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .frame(maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        
                    }) {
                        Label("カメラで撮影", systemImage: "camera")
                    }
                    
                    Button(action: {
                        
                    }) {
                        Label("写真ライブラリから選択", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Label("create", systemImage: "plus")
                }
            }
        }
    }
}

struct TopView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TopView()
        }
    }
}
