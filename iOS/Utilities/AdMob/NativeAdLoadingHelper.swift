//
//  NativeAdLoadingHelper.swift
//  Simple ID Photo (iOS)
//
//  Created by TakashiUshikoshi on 2023/03/17
//
//

import Combine
import GoogleMobileAds

class NativeAdLoadingHelper: NSObject, GADNativeAdLoaderDelegate, ObservableObject {
    
    @Published private(set) var nativeAd: GADNativeAd? = nil
    
    private var advertisementUnitID: String
    
    private var adLoader: GADAdLoader!
    
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

        adLoader.load(GADRequest())
    }
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        self.nativeAd = nativeAd
        
        print(nativeAd.debugDescription)
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print(error)
    }
}
