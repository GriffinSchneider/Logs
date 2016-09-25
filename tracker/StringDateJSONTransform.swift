//
//  StringDateJSONTransform.swift
//  tracker
//
//  Created by Griffin Schneider on 8/31/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import ObjectMapper

class StringDateJSONTransform: TransformType {
    
    typealias Object = Date
    typealias JSON = String
    
    fileprivate static let outputDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
        return df
    }()
    
    fileprivate static let inputDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HHmmssZZZ"
        return df
    }()
    
    init() {}
    
    func transformFromJSON(_ value: Any?) -> Date? {
        if let value = value as? String {
            return StringDateJSONTransform.inputDateFormatter.date(
                from: value.replacingOccurrences(of: ":", with: "")
            )
        }
        return nil
    }
    
    func transformToJSON(_ value: Date?) -> String? {
        if let value = value {
            return StringDateJSONTransform.outputDateFormatter.string(from: value)
        }
        return nil
    }
    
}
