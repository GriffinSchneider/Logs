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
    
    static let schema = Observable<SSchema>.create { obs in
        obs.on(.Next(SSyncManager.schemaFromDisk()))
        return NopDisposable.instance
    }
    
    static let data = Observable<SData>.create { obs in
        obs.on(.Next(SSyncManager.dataFromDisk()))
        return NopDisposable.instance
    }
    
    private static let containerPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.zone.griff.tracker")!
    private static var schemaPath = containerPath.URLByAppendingPathComponent("schema.json")
    private static var dataPath = containerPath.URLByAppendingPathComponent("data.json")
    
    static func schemaFromDisk() -> SSchema {
        return Mapper<SSchema>().map(try! NSString(contentsOfURL: schemaPath, encoding: NSUTF8StringEncoding))!
    }
    
    private static func dataFromDisk() -> SData {
         return Mapper<SData>().map(try! NSString(contentsOfURL: dataPath, encoding: NSUTF8StringEncoding))!
    }
}