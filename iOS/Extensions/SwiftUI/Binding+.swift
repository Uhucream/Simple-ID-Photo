//
//  Binding+.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/22
//  
//

import SwiftUI

extension Binding {
    public static func readOnly(_ value: Value) -> Binding<Value> {
        let getOnlyBindingValue: Binding<Value> = .init {
            return value
        } set: { _ in
        }
        
        return getOnlyBindingValue
    }
}
