//
//  Extensions.swift
//  tracker
//
//  Created by Griffin Schneider on 8/30/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation


extension Array {
    func stride(by by: Int, @noescape block: (e: ArraySlice<Element>) -> ()) {
        0.stride(to: count, by: by).forEach {idx in
            let endIdx = idx.advancedBy(by, limit: count)
            let thing = self[idx ..< endIdx]
            block(e: thing)
        }
    }
}

extension SequenceType {
    func reduce<T>(initial: T, @noescape combine: (T, Int, Generator.Element) throws -> T) rethrows -> T {
        return try enumerate().reduce(initial) { (t: T, tuple: (index: Int, element: Generator.Element)) -> T in
            return try combine(t, tuple.index, tuple.element)
        }
    }
    
}