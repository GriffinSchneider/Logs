//
//  SwiftViewController.swift
//  tracker
//
//  Created by Griffin on 8/25/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import DRYUI


class SwiftViewController: UIViewController {
    
    override func loadView() {
        view = UIView()
        
        if DBSession.sharedSession().isLinked() {
            SyncManager.i().loadFromDisk()
        }
    }
    
    override func viewDidLoad() {
        guard DBSession.sharedSession().isLinked() else {
            DBSession.sharedSession().linkFromController(self)
            return
        }
        
        view.backgroundColor = UIColor.flatNavyBlueColorDark()
        
        let occurrences = SyncManager.i().schema().occurrences
        let activeStates = SyncManager.i().data().activeStates()
        let states = SyncManager.i().schema().states as! [StateSchema]
        
        
        var lastView = spacer(nil)
        
        occurrences.stride(by: 4) { occurrences in
            lastView = buildRow(lastView, data: occurrences) {b, d in
                b.setTitle(d, forState: .Normal)
                b.backgroundColor = UIColor.flatRedColor()
            }
        }
        
        lastView = spacer(lastView)
        
        states.filter { s in activeStates.contains { a in a.name == s.name } }.stride(by: 4) { states in
            lastView = buildRow(lastView, data: states) {b, d in
                b.setTitle(d.name, forState: .Normal)
                b.setTitleColor(UIColor.flatWhiteColorDark(), forState: .Normal)
                b.backgroundColor = UIColor.flatRedColor()
            }
        }
        
        lastView = spacer(lastView)
        
        states.stride(by: 4) { states in
            lastView = buildRow(lastView, data: states) {b, d in
                b.setTitle(d.icon, forState: .Normal)
                b.setTitleColor(UIColor.flatWhiteColorDark(), forState: .Normal)
                b.backgroundColor = UIColor.flatRedColor()
            }
        }
    }
    
    func spacer(lastView: UIView?) -> UIView {
        return view.addSubview {v, make in
            make.top.equalTo(lastView?.snp_bottom ?? view.snp_top).offset(15)
            make.height.equalTo(0)
        }
    }
    
    func buildRow<T>(lastView: UIView, data: ArraySlice<T>, buttonBlock: (b: UIButton, d: T)->Void) -> UIView {
        let lastButton = data.reduce(lastView) { lastView, idx, d in
            return view.addSubview(Style.Button) {b, make in
                buttonBlock(b: b, d: d)
                b.highlightedBackgroundColor = b.backgroundColor?.darkenByPercentage(0.2)
                make.top.equalTo(lastView)
                if idx == 0 {
                    make.left.equalTo(b.superview!).offset(10)
                } else {
                    make.width.equalTo(lastView)
                    make.left.equalTo(lastView.snp_right).offset(10)
                }
                if idx == data.count - 1 {
                    make.right.equalTo(b.superview!).offset(-10)
                }
            }
        }
        return view.addSubview{v, make in
             make.top.equalTo(lastButton.snp_bottom).offset(5)
        }
    }
}