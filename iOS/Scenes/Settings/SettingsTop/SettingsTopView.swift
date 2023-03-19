//
//  SettingsTopView.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/12
//  
//

import SwiftUI

struct SettingsTopView: View {
    
    private var bundleDisplayName: String {
        return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "アプリ"
    }
    
    private var versionNumberString: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }
    
    private var buildNumberString: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }
    
    var body: some View {
        Form {
            
            Section {
                NavigationLink(destination: SettingsAboutView()) {
                    Text("\(bundleDisplayName) について")
                }
            }
            
            Section {
                EmptyView()
            } footer: {
                Text("Version \(versionNumberString) (\(buildNumberString))")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

struct SettingsTopView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTopView()
    }
}
