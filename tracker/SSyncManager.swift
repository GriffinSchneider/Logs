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
    
    static var data:Variable<SData> = {
        let data = Variable(Mapper<SData>().map(try! NSString(contentsOfURL: dataPath, encoding: NSUTF8StringEncoding))!)
        _ = data.asObservable()
            .skip(1)
            .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "DataWriteQueue"))
            .subscribeNext {
                try! $0.toJSONString(true)!.writeToURL(
                    SSyncManager.dataPath,
                    atomically: true,
                    encoding: NSUTF8StringEncoding
                )
        }
        return data
    }()
    
    private static let containerPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.zone.griff.tracker")!
    private static let schemaPath = containerPath.URLByAppendingPathComponent("schema.json")!
    private static let dataPath = containerPath.URLByAppendingPathComponent("data.json")!
}
