//
//  Styles.swift
//  tracker
//
//  Created by Griffin Schneider on 8/30/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation

class Style {
    static func ButtonLabel(_ l: UIButton) {
        l.setTitleColor(UIColor.flatWhite(), for: .normal)
        l.layer.cornerRadius = 5
        l.clipsToBounds = true
    }
}
