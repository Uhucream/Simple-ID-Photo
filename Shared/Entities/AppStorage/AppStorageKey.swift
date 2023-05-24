//
//  AppStorageKey.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/17
//  
//

import Foundation
import SwiftUI

struct AppStorageKey<Value> {
    let name: String
    let defaultValue: Value

    init(_ name: String, defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}
