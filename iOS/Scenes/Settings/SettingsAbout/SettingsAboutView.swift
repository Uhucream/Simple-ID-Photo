//
//  SettingsAboutView.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/12
//  
//

import SwiftUI

struct SettingsAboutView: View {
    
    @ScaledMetric(wrappedValue: 1, relativeTo: .body) private var twitterIconScaleFactor
    
    var body: some View {
        Form {
            Section {
                Link(destination: URL(string: "twitter.com/Ukokkei95Toyama")!) {
                    HStack(alignment: .center) {
                        Image("TwitterIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 16 * twitterIconScaleFactor)
                        
                        Text("@Ukokkei95Toyama")
                            .font(.body)
                    }
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
