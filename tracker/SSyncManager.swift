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
    
    private static let containerPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.zone.griff.tracker")!
    private static var schemaPath = containerPath.URLByAppendingPathComponent("schema.json")
    private static var dataPath = containerPath.URLByAppendingPathComponent("data.json")
    
    static func loadFromDisk() -> SSchema {
        return Mapper<SSchema>().map(try! NSString(contentsOfURL: schemaPath, encoding: NSUTF8StringEncoding))!
    }
    
    static func loadData() -> SData {
        return Mapper<SData>().map(try! NSString(contentsOfURL: dataPath, encoding: NSUTF8StringEncoding))!
    }
}