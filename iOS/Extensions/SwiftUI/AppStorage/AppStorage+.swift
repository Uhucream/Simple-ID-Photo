//
//  AppStorage+.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/22
//  
//

import SwiftUI

// 参考: https://gist.github.com/DivineDominion/3060eaceb6f2f9b65b6d183ac8b8dba9

extension AppStorage where Value == Bool {
    init(wrappedValue: Value, strongKey: AppStorageKey<Value>, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, strongKey.name, store: store)
    }

    /// Testing seam.
    init(
        wrappedValue: Value,
        strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>,
        store: UserDefaults? = nil
    ) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: wrappedValue, strongKey: strongKey, store: store)
    }

    init(
        wrappedValue: Value,
        _ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>
    ) {
        self.init(wrappedValue: wrappedValue, strongKeyPath: strongKeyPath, store: nil)
    }

    /// Testing seam.
    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>, store: UserDefaults? = nil) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: strongKey.defaultValue, strongKey: strongKey, store: store)
    }

    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        self.init(strongKeyPath, store: nil)
    }
}

extension AppStorage where Value == Int {
    init(wrappedValue: Value, strongKey: AppStorageKey<Value>, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, strongKey.name, store: store)
    }

    /// Testing seam.
    init(
        wrappedValue: Value,
        strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>,
        store: UserDefaults? = nil
    ) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: wrappedValue, strongKey: strongKey, store: store)
    }

    init(
        wrappedValue: Value,
        _ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>
    ) {
        self.init(wrappedValue: wrappedValue, strongKeyPath: strongKeyPath, store: nil)
    }

    /// Testing seam.
    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>, store: UserDefaults? = nil) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: strongKey.defaultValue, strongKey: strongKey, store: store)
    }

    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        self.init(strongKeyPath, store: nil)
    }
}

extension AppStorage where Value == Double {
    init(wrappedValue: Value, strongKey: AppStorageKey<Value>, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, strongKey.name, store: store)
    }

    /// Testing seam.
    init(
        wrappedValue: Value,
        strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>,
        store: UserDefaults? = nil
    ) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: wrappedValue, strongKey: strongKey, store: store)
    }

    init(
        wrappedValue: Value,
        _ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>
    ) {
        self.init(wrappedValue: wrappedValue, strongKeyPath: strongKeyPath, store: nil)
    }

    /// Testing seam.
    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>, store: UserDefaults? = nil) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: strongKey.defaultValue, strongKey: strongKey, store: store)
    }

    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        self.init(strongKeyPath, store: nil)
    }
}

extension AppStorage where Value == URL {
    init(wrappedValue: Value, strongKey: AppStorageKey<Value>, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, strongKey.name, store: store)
    }

    /// Testing seam.
    init(
        wrappedValue: Value,
        strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>,
        store: UserDefaults? = nil
    ) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: wrappedValue, strongKey: strongKey, store: store)
    }

    init(
        wrappedValue: Value,
        _ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>
    ) {
        self.init(wrappedValue: wrappedValue, strongKeyPath: strongKeyPath, store: nil)
    }

    /// Testing seam.
    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>, store: UserDefaults? = nil) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: strongKey.defaultValue, strongKey: strongKey, store: store)
    }

    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        self.init(strongKeyPath, store: nil)
    }
}

extension AppStorage where Value == String {
    init(wrappedValue: Value, strongKey: AppStorageKey<Value>, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, strongKey.name, store: store)
    }

    /// Testing seam.
    init(
        wrappedValue: Value,
        strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>,
        store: UserDefaults? = nil
    ) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: wrappedValue, strongKey: strongKey, store: store)
    }

    init(
        wrappedValue: Value,
        _ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>
    ) {
        self.init(wrappedValue: wrappedValue, strongKeyPath: strongKeyPath, store: nil)
    }

    /// Testing seam.
    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>, store: UserDefaults? = nil) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: strongKey.defaultValue, strongKey: strongKey, store: store)
    }

    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        self.init(strongKeyPath, store: nil)
    }
}

extension AppStorage where Value == Data {
    init(wrappedValue: Value, strongKey: AppStorageKey<Value>, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, strongKey.name, store: store)
    }

    /// Testing seam.
    init(
        wrappedValue: Value,
        strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>,
        store: UserDefaults? = nil
    ) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: wrappedValue, strongKey: strongKey, store: store)
    }

    init(
        wrappedValue: Value,
        _ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>
    ) {
        self.init(wrappedValue: wrappedValue, strongKeyPath: strongKeyPath, store: nil)
    }

    /// Testing seam.
    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>, store: UserDefaults? = nil) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]

        self.init(wrappedValue: strongKey.defaultValue, strongKey: strongKey, store: store)
    }

    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        self.init(strongKeyPath, store: nil)
    }
}
