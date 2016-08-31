//
//  SSyncManager.swift
//  tracker
//
//  Created by Griffin Schneider on 8/31/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import ObjectMapper

class SSyncManager {
    
    private static var schemaPath: NSURL {
        return NSFileManager.defaultManager()
            .containerURLForSecurityApplicationGroupIdentifier("group.zone.griff.tracker")!
            .URLByAppendingPathComponent("schema.json")
    }
    
    static func loadFromDisk() -> SSchema {
        return Mapper<SSchema>().map(try! NSString(contentsOfURL: schemaPath, encoding: NSUTF8StringEncoding))!
    }
}