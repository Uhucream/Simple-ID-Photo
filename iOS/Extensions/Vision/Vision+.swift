//
//  Vision+.swift
//  Simple ID Photo (iOS)
//
//  Created by TakashiUshikoshi on 2023/10/08.
//
//

import Vision

extension VNImageRequestHandler {
    public func perform(_ requests: [VNRequest]) async throws {
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try self.perform(requests)
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            requests.forEach { $0.cancel() }
        }
    }
}
