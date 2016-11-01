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
        
        print("LAST: \(data.value.events.last)")
        _ = data.asObservable()
            .skip(1)
            .debounce(0.1, scheduler: MainScheduler.instance)
            .map { data -> (SData, UIBackgroundTaskIdentifier?) in
                #if IS_TODAY_EXTENSION
                    return (data, nil)
                #else
                    let taskId = UIApplication.shared.beginBackgroundTask {
                        print("Background task terminated!")
                    }
                    print("Beginning background task: \(taskId)")
                    return (data, taskId)
                #endif
            }
            .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "DataWriteQueue"))
            .subscribe(onNext: {
                do {
                    try $0.0.toJSONString(prettyPrint: true)!.write(
                        to: SSyncManager.dataPath,
                        atomically: true,
                        encoding: .utf8
                    )
                    #if !IS_TODAY_EXTENSION
                        print("Completing background task: \($0.1)")
                        UIApplication.shared.endBackgroundTask($0.1!)
                    #endif
                } catch {
                    print("EXCEPTION: \(error)")
                }
            })
        return data
    }()
    
    private static let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.zone.griff.tracker")!
    private static let schemaPath = containerPath.appendingPathComponent("schema.json")
    private static let dataPath = containerPath.appendingPathComponent("data.json")
    
    private static func dataFromDisk() -> SData {
        let string = (try? String(contentsOf: dataPath, encoding: .utf8)) ?? "{}"
        return Mapper<SData>().map(JSONString: string) ?? Mapper<SData>().map(JSONString: "{}")!
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
