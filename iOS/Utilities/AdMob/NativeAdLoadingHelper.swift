//
//  NativeAdLoadingHelper.swift
//  Simple ID Photo (iOS)
//
//  Created by TakashiUshikoshi on 2023/03/17
//
//

import Combine
import GoogleMobileAds

class NativeAdLoadingHelper: NSObject, NativeAdLoaderDelegate, ObservableObject {
    
    @Published private(set) var nativeAd: NativeAd? = nil
    
    private var advertisementUnitID: String
    
    private var adLoader: AdLoader!
    
    init(advertisementUnitID: String) {
        self.advertisementUnitID = advertisementUnitID
    }
    
    func refreshAd() {
        adLoader = .init(
            adUnitID: self.advertisementUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        
        adLoader.delegate = self

        adLoader.load(Request())
    }
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAd = nativeAd
        
        print(nativeAd.debugDescription)
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print(error)
    }
}
