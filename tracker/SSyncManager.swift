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
    static var schema = Variable(Mapper<SSchema>().map(JSONString: try! String(contentsOf: schemaPath, encoding: .utf8))!)
    
    static var data:Variable<SData> = {
        print(dataPath)
        let data = Variable(Mapper<SData>().map(JSONString: try! String(contentsOf: dataPath, encoding: .utf8))!)
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
    
    fileprivate static let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.zone.griff.tracker")!
    fileprivate static let schemaPath = containerPath.appendingPathComponent("schema.json")
    fileprivate static let dataPath = containerPath.appendingPathComponent("data.json")
}
