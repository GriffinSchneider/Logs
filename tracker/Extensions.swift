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
    func stride(by by: Int, @noescape block: (e: ArraySlice<Element>) -> Void) {
        0.stride(to: count, by: by).forEach {idx in
            let endIdx = idx.advancedBy(by, limit: count)
            let thing = self[idx ..< endIdx]
            block(e: thing)
        }
    }
}

extension Array where Element: Comparable {
    mutating func sortedAppend(toInsert: Generator.Element) {
        for idx in (0...(count-1)).reverse() {
            let element = self[idx]
            if element < toInsert {
                insert(toInsert, atIndex: idx + 1)
                return
            }
        }
        insert(toInsert, atIndex: 0)
    }
}

extension SequenceType {
    func reduce<T>(initial: T, @noescape combine: (T, Int, Generator.Element) throws -> T) rethrows -> T {
        return try enumerate().reduce(initial) { (t: T, tuple: (index: Int, element: Generator.Element)) -> T in
            return try combine(t, tuple.index, tuple.element)
        }
    }
}
