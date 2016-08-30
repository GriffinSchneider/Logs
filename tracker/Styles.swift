//
//  Styles.swift
//  tracker
//
//  Created by Griffin Schneider on 8/30/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation


class Style {
    
    static func Button(b: UIButton) {
        b.setTitleColor(UIColor.flatWhiteColor(), forState: .Normal)
        b.layer.cornerRadius = 5
    }
    
}