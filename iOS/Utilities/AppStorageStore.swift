//
//  AppStorageStore.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/17
//  
//

import SwiftUI

final class AppStorageStore: ObservableObject {
    
    static let shared: AppStorageStore = .init()
    
    @AppStorage(.isHideAdPurchased) var isHideAdPurchased = false
}
