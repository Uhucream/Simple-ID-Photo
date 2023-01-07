//
//  TopView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import SwiftUI

struct TopView: View {
    @EnvironmentObject var screenSizeHelper: ScreenSizeHelper
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Button(action: {
                        
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "photo.on.rectangle.angled")
                            
                            Text("アルバムから選択")
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.systemGray3)

                    Button(action: {
                        
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "camera")
                            
                            Text("カメラで撮影")
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.cyan)
                }
                .padding()
                
                VStack {
                    Spacer()
                    
                    Text("作成された証明写真がありません")
                        .foregroundColor(.secondaryLabel)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minHeight: screenSizeHelper.screenHeight)
        }
    }
}

struct TopView_Previews: PreviewProvider {
    static var previews: some View {
        let screenSizeHelper: ScreenSizeHelper = .shared
        
        GeometryReader { geometry in
            TopView()
                .onAppear {
                    screenSizeHelper.update(screenWidth: geometry.size.width, screenHeight: geometry.size.height)
                }
                .onChange(of: geometry.size) { (screenSize: CGSize) in
                    screenSizeHelper.update(screenWidth: screenSize.width, screenHeight: screenSize.height)
                }
        }
        .environmentObject(screenSizeHelper)
    }
}
