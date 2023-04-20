//
//  SavingProgressView.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/04/20
//  
//

import SwiftUI
import Percentage

struct SavingProgressView: View {
    
    @Binding var savingStatus: SavingStatus
    
    var body: some View {
        Group {
            GeometryReader { geometry in
                if savingStatus == .inProgress {
                    ProgressView("保存しています")
                        .foregroundColor(.label)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                
                if savingStatus == .succeeded {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 30%.of(geometry.size.height))
                        
                        Text("保存しました!")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                
                if savingStatus == .failed {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 30%.of(geometry.size.height))
                        
                        Text("失敗しました")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .font(.title3)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .aspectRatio(1, contentMode: .fit)
    }
}

struct SavingProgressView_Previews: PreviewProvider {
    static var previews: some View {
        SavingProgressView(savingStatus: .constant(.inProgress))
            .frame(width: 200)
    }
}
