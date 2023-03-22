//
//  AppStorage+.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/22
//  
//

import SwiftUI

extension AppStorage {
    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == Bool {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == Int {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == Double {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == URL {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == String {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == Data {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
}

extension AppStorage where Value : ExpressibleByNilLiteral {
    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == Bool? {
        self.init(key.rawValue, store: store)
    }

    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == Int? {
        self.init(key.rawValue, store: store)
    }

    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == Double? {
        self.init(key.rawValue, store: store)
    }

    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == URL? {
        self.init(key.rawValue, store: store)
    }

    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == String? {
        self.init(key.rawValue, store: store)
    }

    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == Data? {
        self.init(key.rawValue, store: store)
    }
}
