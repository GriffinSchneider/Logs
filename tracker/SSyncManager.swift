//
//  SSyncManager.swift
//  tracker
//
//  Created by Griffin Schneider on 8/31/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import ObjectMapper
import RxSwift

class SSyncManager {
    static var schema = Variable(Mapper<SSchema>().map(try! NSString(contentsOfURL: schemaPath, encoding: NSUTF8StringEncoding))!)
    static var data = Variable(Mapper<SData>().map(try! NSString(contentsOfURL: dataPath, encoding: NSUTF8StringEncoding))!)
    
    private static let containerPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.zone.griff.tracker")!
    private static var schemaPath = containerPath.URLByAppendingPathComponent("schema.json")
    private static var dataPath = containerPath.URLByAppendingPathComponent("data.json")
}