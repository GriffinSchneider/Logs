//
//  AppDelegate.swift
//  tracker
//
//  Created by Griffin on 2/25/17.
//  Copyright © 2017 griff.zone. All rights reserved.
//

import Foundation
import UserNotifications
import SwiftyDropbox

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]){ granted, error in
            
        }
        
        let vc = MainViewController()
        let nc = UINavigationController()
        nc.isNavigationBarHidden = true
        
        let _ = SyncManager.data
        NotificationManager.setup(vc: vc)
        SyncManager.viewController = vc
        
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = UIColor.flatNavyBlue()
        UINavigationBar.appearance().tintColor = UIColor.flatWhiteColorDark()
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.flatWhiteColorDark()]
        
        SyncManager.initialize()
       
        self.window = UIWindow()
        self.window?.makeKeyAndVisible()
        self.window?.rootViewController = nc
        nc.viewControllers = [vc]
        
        DropboxClientsManager.setupWithAppKey(kDropBoxAPIKey)
        
        if DropboxClientsManager.authorizedClient == nil {
            DropboxClientsManager.authorizeFromController(
                UIApplication.shared,
                controller: vc,
                openURL: { (url: URL) -> Void in
                    UIApplication.shared.open(url)
                }
            )
        } else {
            dropboxAuthenticated()
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
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
