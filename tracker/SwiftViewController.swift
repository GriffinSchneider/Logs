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
import SnapKit

let SPACING: CGFloat = 5.0
let SECTION_INSETS = UIEdgeInsets(top: 30, left: 10, bottom: 0, right: 10)
let BUTTON_INSETS = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

class SwiftViewController: UIViewController {
    
    override func loadView() {
        view = UIView()
        if DBSession.sharedSession().isLinked() {
            SyncManager.i().loadFromDisk()
        }
    }
    
    override func viewDidLoad() {
//        guard DBSession.sharedSession().isLinked() else {
//            dispatch_async(dispatch_get_main_queue()) {
//                DBSession.sharedSession().linkFromController(self)
//            }
//            return
//        }
        
        view.backgroundColor = UIColor.flatNavyBlueColorDark()
        
        let fl = UICollectionViewFlowLayout()
        fl.estimatedItemSize = CGSizeMake(10, 10)
        fl.sectionInset = SECTION_INSETS
        fl.scrollDirection = .Vertical;
        fl.minimumInteritemSpacing = SPACING
        fl.minimumLineSpacing = 5
        view.addSubview(UICollectionView(frame: CGRectZero, collectionViewLayout: fl)) { v, make in
            v.delaysContentTouches = false
            v.backgroundColor = UIColor.flatNavyBlueColorDark()
            v.registerClass(ButtonCollectionViewCell.self, forCellWithReuseIdentifier: "id")
            v.delegate = self
            v.dataSource = self
            make.edges.equalTo(v.superview!)
        }
    }
}

extension SwiftViewController: UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return SyncManager.i().schema().occurrences.count
        case 1:
            return SyncManager.i().data().activeStates().count
        case 2:
            return SyncManager.i().schema().states.count
        case 3:
            return SyncManager.i().schema().readings.count
        default:
            assert(false)
        }
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("id", forIndexPath: indexPath) as! ButtonCollectionViewCell
        cell.setup(UIEdgeInsetsInsetRect(collectionView.bounds, SECTION_INSETS))
        cell.update { l in
            switch indexPath.section {
            case 0:
                let occurrence = SyncManager.i().schema().occurrences[indexPath.row]
                l.text = occurrence
            case 1:
                let activeState = SyncManager.i().data().activeStates()[indexPath.row]
                l.text = "\(activeState.name) \(formatDuration(NSDate().timeIntervalSinceDate(activeState.date)))"
            case 2:
                let state = SyncManager.i().schema().states[indexPath.row] as! StateSchema
                l.text = state.icon
            case 3:
                let reading =  SyncManager.i().schema().readings[indexPath.row]
                l.text = reading
            default:
                assert(false)
            }
        }
        return cell
    }
}

extension SwiftViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        NSLog("\(indexPath)")
    }
}


class ButtonCollectionViewCell: UICollectionViewCell {
    
    private var label: UILabel!
    private var hasBeenSetup = false
    func setup(superBounds: CGRect) {
        guard !hasBeenSetup else { return }
        hasBeenSetup = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        label = contentView.addSubview(Style.ButtonLabel) {v, make in
            make.edges.equalTo(v.superview!).inset(BUTTON_INSETS)
            make.width.greaterThanOrEqualTo(40)
        }
    }
    
    func update(block: (UILabel) -> Void) {
        block(label)
    }
    
    override var highlighted: Bool {
        get { return super.highlighted }
        set {
            super.highlighted = newValue
            label?.backgroundColor = UIColor.randomFlatColor()
        }
    }
}
