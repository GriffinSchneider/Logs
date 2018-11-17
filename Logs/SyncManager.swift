//
//  SSyncManager.swift
//  tracker
//
//  Created by Griffin Schneider on 8/31/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyDropbox
import Toast_Swift

@objc class SyncManager: NSObject {
    public static var viewController: UIViewController? = nil

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
        return df
    }()

    private static let jsonEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .prettyPrinted
        e.dateEncodingStrategy = .formatted(dateFormatter)
        return e
    }()

    private static let jsonDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .formatted(dateFormatter)
        return d
    }()
    
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
                    try jsonEncoder.encode($0.0).write(to: SyncManager.dataPath, options: .atomic)
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
    
    private static let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.zone.griff.logs")!
    private static let schemaPath = containerPath.appendingPathComponent("schema.json")
    private static let dataPath = containerPath.appendingPathComponent("data.json")

    private static func dataFromDisk() -> Data {
        do {
            let nsdata = try Foundation.Data(contentsOf: dataPath)
            let decoded = try jsonDecoder.decode(Data.self, from: nsdata)
            return decoded
        }
        catch {
            print("Exception decoding data: \(error)")
        }
        return Data()
    }
    
    private static func schemaFromDisk() -> Schema {
        do {
            let nsdata = try Foundation.Data(contentsOf: schemaPath)
            let decoded = try jsonDecoder.decode(Schema.self, from: nsdata)
            return decoded
        } catch {
            print("Exception decoding schema: \(error)")
        }
        return Schema()
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
