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

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        CSToastManager.setQueueEnabled(false)
        DropboxSessionManager.i().setupSession()
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = UIColor.flatNavyBlue()
        UINavigationBar.appearance().tintColor = UIColor.flatWhiteColorDark()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.flatWhiteColorDark()]
        SSyncManager.initialize()
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]){ granted, error in
        }
        self.window = UIWindow()
        self.window?.rootViewController = SwiftViewController()
        self.window?.makeKeyAndVisible()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return DropboxSessionManager.i().handleOpen(url)
    }
    
}
