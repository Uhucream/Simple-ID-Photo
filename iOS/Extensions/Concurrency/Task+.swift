//
//  Task+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/12
//  
//

import Foundation

extension Task where Success == Never, Failure == Never {
    @available(iOS, deprecated: 15)
    static func sleep(milliseconds duration: UInt64) async throws -> Void {
        
        let oneMillisecond: UInt64 = 1_000_000
        
        try await Task.sleep(nanoseconds: oneMillisecond * duration)
    }
}
