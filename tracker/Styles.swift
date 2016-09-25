//
//  Styles.swift
//  tracker
//
//  Created by Griffin Schneider on 8/30/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation

class TrackerLabel: UILabel {
    override var intrinsicContentSize : CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: max(60, s.width + 10), height: s.height + 10)
    }
}

class Style {
    static func ButtonLabel(_ l: TrackerLabel) {
        l.textColor = UIColor.flatWhite()
        l.layer.cornerRadius = 5
        l.clipsToBounds = true
        l.textAlignment = .center
    }
}
