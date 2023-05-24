//
//  AppStorageKeys.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/05/24
//  
//

import Foundation

struct AppStorageKeys { init() { } }

extension AppStorageKeys {
    var isHideAdPurchased: AppStorageKey<Bool> {
        .init("isHideAdPurchased", defaultValue: false)
    }
}
