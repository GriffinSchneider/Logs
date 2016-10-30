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

@objc class SSyncManager: NSObject {
    static var schema = Variable(schemaFromDisk())
    
    static var data:Variable<SData> = {
        print(dataPath)
        let data = Variable(dataFromDisk())
        _ = data.asObservable()
            .skip(1)
            .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "DataWriteQueue"))
            .subscribe(onNext: {
                try! $0.toJSONString(prettyPrint: true)!.write(
                    to: SSyncManager.dataPath,
                    atomically: true,
                    encoding: String.Encoding.utf8
                )
            })
        return data
    }()
    
    private static let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.zone.griff.tracker")!
    private static let schemaPath = containerPath.appendingPathComponent("schema.json")
    private static let dataPath = containerPath.appendingPathComponent("data.json")
    
    private static func dataFromDisk() -> SData {
        let string = (try? String(contentsOf: dataPath, encoding: .utf8)) ?? "{}"
        return Mapper<SData>().map(JSONString: string)!
    }
    
    private static func schemaFromDisk() -> SSchema {
        let string = (try? String(contentsOf: schemaPath, encoding: .utf8)) ?? "{}"
        return Mapper<SSchema>().map(JSONString: string)!
    }
    
    @objc static func loadFromDisk() {
        schema.value = schemaFromDisk()
        data.value = dataFromDisk()
    }
}
