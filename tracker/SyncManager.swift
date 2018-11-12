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
import SwiftyDropbox
import Toast_Swift

@objc class SyncManager: NSObject {
    public static var viewController: UIViewController? = nil
    
    static var schema = Variable(schemaFromDisk())
    
    static var data:Variable<Data> = {
        print(dataPath)
        let data = Variable(dataFromDisk())
        _ = data.asObservable()
            .skip(1)
            .debounce(0.1, scheduler: MainScheduler.instance)
            .map { data -> (Data, UIBackgroundTaskIdentifier?) in
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
                        to: SyncManager.dataPath,
                        atomically: true,
                        encoding: .utf8
                    )
                    #if !IS_TODAY_EXTENSION
                        print("Completing background task: \(String(describing: $0.1))")
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
    
    private static func dataFromDisk() -> Data {
        let string = (try? String(contentsOf: dataPath, encoding: .utf8)) ?? "{}"
        return Mapper<Data>().map(JSONString: string) ?? Mapper<Data>().map(JSONString: "{}")!
    }
    
    private static func schemaFromDisk() -> Schema {
        let string = (try? String(contentsOf: schemaPath, encoding: .utf8)) ?? "{}"
        return Mapper<Schema>().map(JSONString: string) ?? Mapper<Schema>().map(JSONString: "{}")!
    }
    
    @objc static func loadFromDisk() {
        schema.value = schemaFromDisk()
        data.value = dataFromDisk()
    }
    
    static func upload() {
        let rev = UserDefaults.standard.value(forKey: "DATA_REV") as? String
        DispatchQueue.main.async { viewController?.view.makeToastActivity(.center) }
        DropboxClientsManager.authorizedClient!.files.upload(
            path: "/data.json",
            mode: .update(rev ?? ""),
            input: dataPath
        ).response { response, error in
            DispatchQueue.main.async { viewController?.view.hideToastActivity() }
            if let response = response {
                DispatchQueue.main.async { viewController?.view.makeToast("✅") }
                UserDefaults.standard.set(response.rev, forKey: "DATA_REV")
                print(response)
            } else if let error = error {
                DispatchQueue.main.async { viewController?.view.makeToast("🙅🏻\(error)") }
                print(error)
            }
        }.progress { progressData in
            print(progressData)
        }
    }
    
    private static func download(path: String, url: URL, revKey: String) {
        DispatchQueue.main.async { viewController?.view.makeToastActivity(.center) }
        DropboxClientsManager.authorizedClient!.files.download(path: path, overwrite: true) { _, _ in
            return url
        }.response { response, error in
            DispatchQueue.main.async { viewController?.view.hideToastActivity() }
            if let response = response {
                DispatchQueue.main.async { viewController?.view.makeToast("✅") }
                UserDefaults.standard.set(response.0.rev, forKey: revKey)
                self.loadFromDisk()
                print(response)
            } else if let error = error {
                DispatchQueue.main.async { viewController?.view.makeToast("🙅🏻\(error)") }
                print(error)
            }
        }.progress { progressData in
            print(progressData)
        }
    }
    
    static func download() {
        download(path: "/data.json", url: dataPath, revKey: "DATA_REV")
        download(path: "/schema.json", url: schemaPath, revKey: "SCHEMA_REV")
    }
}
