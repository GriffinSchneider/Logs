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
        if (count < 1) {
            insert(toInsert, at: 0)
        }
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

extension NSAttributedString {
    static func build(_ strings: (String, [NSAttributedString.Key : Any])...) -> NSAttributedString {
        let retVal = NSMutableAttributedString()
        strings.forEach { retVal.append(NSAttributedString(string: $0.0, attributes: $0.1)) }
        return retVal
    }
    
    static func build(_ strings: (Bool?, String?, [NSAttributedString.Key : Any])...) -> NSAttributedString {
        let retVal = NSMutableAttributedString()
        strings.forEach {
            guard let b = $0.0, b else { return }
            retVal.append(NSAttributedString(string: $0.1!, attributes: $0.2))
        }
        return retVal
    }
}
