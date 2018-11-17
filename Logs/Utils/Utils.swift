//
//  Utils.swift
//  tracker
//
//  Created by Griffin Schneider on 11/16/18.
//  Copyright © 2018 griff.zone. All rights reserved.
//

import Foundation
import DRYUI

func timeAgoString(fromDate date: Date) -> String? {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    let components = NSCalendar.current.dateComponents([
        .year, .day, .hour, .minute, .second
    ], from: date, to: Date())
    guard let timeString = formatter.string(for: components) else {
        return nil
    }
    return "\(timeString) ago"
}
