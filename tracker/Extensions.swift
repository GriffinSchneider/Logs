//
//  Extensions.swift
//  tracker
//
//  Created by Griffin Schneider on 8/30/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import RxSwift

extension Array {
    func stride(by: Int, block: @escaping (_ e: ArraySlice<Element>) -> Void) {
       Swift.stride(from: 0, to: count, by: by).forEach {idx in
            let endIdx = index(idx, offsetBy: by)
            let thing = self[idx ..< endIdx]
            block(thing)
        }
    }
}

extension Array where Element: Comparable {
    mutating func sortedAppend(_ toInsert: Iterator.Element) {
        for idx in (0...(count-1)).reversed() {
            let element = self[idx]
            if element < toInsert {
                insert(toInsert, at: idx + 1)
                return
            }
        }
        insert(toInsert, at: 0)
    }
}

extension Sequence {
    func reduce<T>(_ initial: T, combine: (T, Int, Iterator.Element) throws -> T) rethrows -> T {
        return try enumerated().reduce(initial) { (t: T, tuple: (index: Int, element: Iterator.Element)) -> T in
            return try combine(t, tuple.index, tuple.element)
        }
    }
}
