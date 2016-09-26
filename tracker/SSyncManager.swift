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
    static var schema = Variable(Mapper<SSchema>().map(SSyncManager.fromDisk(schemaPath) ?? "{}")!)
    
    static var data:Variable<SData> = {
        let data = Variable(Mapper<SData>().map(SSyncManager.fromDisk(dataPath) ?? "{}")!)
        _ = data.asObservable()
            .skip(1)
            .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "DataWriteQueue"))
            .subscribeNext {
                try! $0.toJSONString(true)!.writeToURL(
                    SSyncManager.dataPath!,
                    atomically: true,
                    encoding: NSUTF8StringEncoding
                )
        }
        return data
    }()
    
    private static func fromDisk(path: NSURL?) -> String? {
        guard let path = path else { return nil }
        return try? String(contentsOfURL: path, encoding: NSUTF8StringEncoding)
    }
    
    private static let containerPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.zone.griff.tracker")!
    private static let schemaPath = containerPath.URLByAppendingPathComponent("schema.json")
    private static let dataPath = containerPath.URLByAppendingPathComponent("data.json")
}
