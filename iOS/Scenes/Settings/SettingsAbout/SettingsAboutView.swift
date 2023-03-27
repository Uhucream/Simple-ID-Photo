//
//  SettingsAboutView.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/12
//  
//

import SwiftUI

fileprivate struct TwitterAccountCard: View {
    
    let userName: String
    
    var body: some View {
        HStack(alignment: .center) {
            Image("TwitterIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Text("@\(userName)")
                .font(.body)
        }
    }
}

struct SettingsAboutView: View {
    
    @ScaledMetric(wrappedValue: 1, relativeTo: .body) private var twitterIconScaleFactor
    
    var body: some View {
        Form {
            Section {
                Link(destination: URL(string: "https://twitter.com/Ukokkei95Toyama")!) {
                    TwitterAccountCard(userName: "Ukokkei95Toyama")
                        .frame(maxHeight: 16 * twitterIconScaleFactor)
                }
                
                Link(destination: URL(string: "https://twitter.com/nobtakajp")!) {
                    TwitterAccountCard(userName: "NobtakaJP")
                        .frame(maxHeight: 16 * twitterIconScaleFactor)
                }
            } header: {
                Text("Developed By")
            }
        }
    }
}

struct SettingsAboutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAboutView()
    }
}
