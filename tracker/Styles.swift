//
//  Styles.swift
//  tracker
//
//  Created by Griffin Schneider on 8/30/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation

class TrackerLabel: UILabel {
    override func intrinsicContentSize() -> CGSize {
        let s = super.intrinsicContentSize()
        return CGSizeMake(max(60, s.width + 10), s.height + 10)
    }
}

class Style {
    static func ButtonLabel(l: TrackerLabel) {
        l.textColor = UIColor.flatWhiteColor()
        l.layer.cornerRadius = 5
        l.clipsToBounds = true
        l.textAlignment = .Center
    }
}