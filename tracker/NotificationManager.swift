//
//  NotificationManager.swift
//  tracker
//
//  Created by Griffin on 2/25/17.
//  Copyright © 2017 griff.zone. All rights reserved.
//

import Foundation
import UserNotifications
import AudioToolbox

class NotificationManager {
    
    fileprivate static let readingReminderId0 = "ReadingReminder0"
    fileprivate static let readingReminderId30 = "ReadingReminder30"
    fileprivate static let reminderIds = [readingReminderId0, readingReminderId30]
    
    private static var centerDelegate: _NotificationDelegate!
    static func setup(vc: SwiftViewController) {
        
        centerDelegate = _NotificationDelegate(vc: vc)
        UNUserNotificationCenter.current().delegate = centerDelegate
        
        let _ = SSyncManager.data.asObservable().subscribe(onNext: { d in
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            
            let active = d.activeStates()
            
            guard (!active.contains { $0.name == EVENT_SLEEP }) else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Do a reading!"
            content.body = "📝📝📝📝📝📝📝📝📝"
            
            var dateInfo = DateComponents()
            dateInfo.minute = 0
            center.add(UNNotificationRequest(
                identifier: readingReminderId0,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: true)
            ))
            dateInfo.minute = 30
            center.add(UNNotificationRequest(
                identifier: readingReminderId30,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: true)
            ))
        })
    }

}

private class _NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let vc: SwiftViewController
    init(vc: SwiftViewController) {
        self.vc = vc
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let content = notification.request.content
        let ac = UIAlertController(title: content.title, message: content.body, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "👌🏻", style: .default) { _ in
            self.userOpenedNotification(notification)
        })
        vc.present(ac, animated: true)
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        userOpenedNotification(response.notification)
    }
    
    func userOpenedNotification(_ notification: UNNotification) {
        if NotificationManager.reminderIds.contains(notification.request.identifier) {
            vc.doReading()
        }
    }
}
