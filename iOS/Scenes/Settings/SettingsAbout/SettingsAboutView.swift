//
//  SettingsAboutView.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/12
//  
//

import SwiftUI
import BetterSafariView

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
    
    @State private var presentingPrivacyPolicyURL: URL? = nil
    
    func openPrivacyPolicyWithSFSafariView(_ url: URL) -> OpenURLAction.Result {
        
        self.presentingPrivacyPolicyURL = url
        
        return .handled
    }
    
    var body: some View {
        Form {
            Section {
                Link(destination: URL(string: "https://simpleidphoto.web.app/app/privacy-policy.html")!) {
                    Text("プライバシーポリシー")
                        .foregroundColor(.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .environment(\.openURL, OpenURLAction(handler: openPrivacyPolicyWithSFSafariView))
                .background {
                    //  MARK: Disclosure Indicator 表示用
                    NavigationLink(destination: EmptyView()) {
                        EmptyView()
                    }
                    .disabled(true)
                }
            }
            
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
        .safariView(item: $presentingPrivacyPolicyURL) { url in
            SafariView(
                url: url,
                configuration: .init(
                    entersReaderIfAvailable: false,
                    barCollapsingEnabled: false
                )
            )
        }
    }
}

struct SettingsAboutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAboutView()
    }
}
