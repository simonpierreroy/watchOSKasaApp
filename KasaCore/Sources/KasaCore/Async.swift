//
//  Async.swift
//  
//
//  Created by Simon-Pierre Roy on 8/10/22.
//

import Foundation

public func taskSleep(for duration: Duration = .seconds(2)) async throws -> Void {
    // avoid potential thread hop on zero duration
    if duration > .zero {
        try await Task.sleep(until: .now  + duration , clock: .continuous)
    }
}
