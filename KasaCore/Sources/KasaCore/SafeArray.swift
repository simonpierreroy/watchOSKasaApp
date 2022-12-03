//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 10/3/20.
//

import Foundation

extension Array {
    public subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}
