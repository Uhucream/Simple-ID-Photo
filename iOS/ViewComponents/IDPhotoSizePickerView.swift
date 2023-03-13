//
//  IDPhotoSizePickerView.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/01/09
//  
//

import SwiftUI

struct SizeSelectionCard: View {
    var photoCentiMeterWidth: Double
    var photoCentiMeterHeight: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Rectangle()
                .aspectRatio(photoCentiMeterWidth / photoCentiMeterHeight, contentMode: .fit)
                .foregroundColor(.cyan)
                .frame(maxWidth: 80)
                .overlay {
                    VStack {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                }
            
            VStack(spacing: 4) {
                Text("\(String(format: "%.1f", photoCentiMeterHeight)) cm x \(String(format: "%.1f", photoCentiMeterWidth)) cm")
                    .font(.title3)
                    .fontWeight(.medium)
                
                HStack(alignment: .center) {
                    Text("パスポート など")
                    
                    Image(systemName: "info.circle")
                }
                .font(.footnote)
            }
        }
    }
}

struct IDPhotoSizePickerView: View {
    @State var searchText: String = ""
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(), .init()], spacing: 24) {
                SizeSelectionCard(photoCentiMeterWidth: 3.0, photoCentiMeterHeight: 4.0)
                    .padding()
                    .frame(maxHeight: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondarySystemBackground)
                    }

                SizeSelectionCard(photoCentiMeterWidth: 2.4, photoCentiMeterHeight: 3.0)
                    .padding()
                    .frame(maxHeight: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondarySystemBackground)
                    }
                
                SizeSelectionCard(photoCentiMeterWidth: 2.5, photoCentiMeterHeight: 3.5)
                    .padding()
                    .frame(maxHeight: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondarySystemBackground)
                    }
            }
            .searchable(
                text: $searchText,
                prompt: Text("用途で検索")
            )
            .padding()
        }
    }
}

struct IDPhotoSizePickerView_Previews: PreviewProvider {
    static var previews: some View {
        IDPhotoSizePickerView()
    }
}
