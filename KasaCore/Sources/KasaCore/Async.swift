//
//  Async.swift
//  
//
//  Created by Simon-Pierre Roy on 8/10/22.
//

import Foundation

#if DEBUG
public func taskSleep(for seconds: UInt64 = 2) async throws -> Void {
    if seconds > 0 {
        try await Task.sleep(nanoseconds: NSEC_PER_SEC * seconds)
    }
}
#endif
