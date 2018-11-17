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

extension UIView {
    /// A convenience method intended to be used to space out views in a vertical stack view.
    /// - returns A `UIView` instance constrained to the given height using auto-layout.
    public class func spacer(withHeight height: CGFloat) -> Self {
        return buildView { v, make in
            v.backgroundColor = .clear
            make.height.equalTo(height)
        }
    }

    /// A convenience method intended to be used to space out views in a horiztonal stack view.
    /// - returns A `UIView` instance constrained to the given width using auto-layout.
    public class func spacer(withWidth width: CGFloat) -> Self {
        return buildView { v, make in
            v.backgroundColor = .clear
            make.width.equalTo(width)
        }
    }
}
