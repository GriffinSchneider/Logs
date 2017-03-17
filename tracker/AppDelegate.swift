//
//  AppDelegate.swift
//  tracker
//
//  Created by Griffin on 2/25/17.
//  Copyright © 2017 griff.zone. All rights reserved.
//

import Foundation
import Toast
import UserNotifications
import SwiftyDropbox

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        CSToastManager.setQueueEnabled(false)
       
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]){ granted, error in
            
        }
        
        let vc = SwiftViewController()
        
        let _ = SSyncManager.data
        NotificationManager.setup(vc: vc)
        
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = UIColor.flatNavyBlue()
        UINavigationBar.appearance().tintColor = UIColor.flatWhiteColorDark()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.flatWhiteColorDark()]
        
        SSyncManager.initialize()
       
        self.window = UIWindow()
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
        
        DropboxClientsManager.setupWithAppKey(kDropBoxAPIKey)
        
        if DropboxClientsManager.authorizedClient == nil {
            DropboxClientsManager.authorizeFromController(
                UIApplication.shared,
                controller: vc,
                openURL: { (url: URL) -> Void in
                    UIApplication.shared.openURL(url)
                }
            )
        } else {
            dropboxAuthenticated()
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if let authResult = DropboxClientsManager.handleRedirectURL(url) {
            switch authResult {
            case .success:
                dropboxAuthenticated()
                print("Success! User is logged into Dropbox.")
            case .cancel:
                print("Authorization flow was manually canceled by user!")
            case .error(_, let description):
                print("Error: \(description)")
            }
        }
        return true
    }
    
    func dropboxAuthenticated() {

    }
}
