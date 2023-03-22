//
//  AppDelegate.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/13
//  
//

import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    
    private let appStorageStore: AppStorageStore = .shared
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        if !appStorageStore.isHideAdPurchased {
            GADMobileAds.sharedInstance().start()
        }
        
        return true
    }
}
