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
    
    typealias Object = NSDate
    typealias JSON = String
    
    private static let outputDateFormatter: NSDateFormatter = {
        let df = NSDateFormatter()
        df.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
        return df
    }()
    
    private static let inputDateFormatter: NSDateFormatter = {
        let df = NSDateFormatter()
        df.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HHmmssZZZ"
        return df
    }()
    
    init() {}
    
    func transformFromJSON(value: AnyObject?) -> NSDate? {
        if let value = value as? String {
            return StringDateJSONTransform.inputDateFormatter.dateFromString(
                value.stringByReplacingOccurrencesOfString(":", withString: "")
            )
        }
        return nil
    }
    
    func transformToJSON(value: NSDate?) -> String? {
        if let value = value {
            return StringDateJSONTransform.outputDateFormatter.stringFromDate(value)
        }
        return nil
    }
    
}