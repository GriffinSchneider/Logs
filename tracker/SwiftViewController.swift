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
import RxCocoa
import RxDataSources
import DRYUI
import SnapKit

let SPACING: CGFloat = 5.0
let SECTION_INSETS = UIEdgeInsets(top: 30, left: 10, bottom: 0, right: 10)
let BUTTON_INSETS = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

struct SectionOfCustomData {
    var items: [Item]
}
extension SectionOfCustomData: SectionModelType {
    typealias Item = AnyObject
    
    init(original: SectionOfCustomData, items: [Item]) {
        self = original
        self.items = items
    } 
}

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
        let cv = view.addSubview(UICollectionView(frame: CGRectZero, collectionViewLayout: fl)) { v, make in
            v.delaysContentTouches = false
            v.backgroundColor = UIColor.flatNavyBlueColorDark()
            v.registerClass(ButtonCollectionViewCell.self, forCellWithReuseIdentifier: "id")
            make.edges.equalTo(v.superview!)
        }
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionOfCustomData>()
        
        dataSource.configureCell = { ds, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("id", forIndexPath: indexPath) as! ButtonCollectionViewCell
            cell.setup(UIEdgeInsetsInsetRect(collectionView.bounds, SECTION_INSETS))
            
            switch indexPath.section {
            case 0:
                cell.update(occurrence: item as! String)
            case 1:
                cell.update(activeState: item as! EEvent)
            case 2:
                cell.update(state: item as! StateSchema)
            case 3:
                cell.update(reading: item as! String)
            default:
                assert(false)
            }
            
            return cell
        }
        
        let sections = [
            SectionOfCustomData(items: SyncManager.i().schema().occurrences),
            SectionOfCustomData(items: SyncManager.i().data().activeStates()),
            SectionOfCustomData(items: SyncManager.i().schema().states),
            SectionOfCustomData(items: SyncManager.i().schema().readings),
        ]
        
        _ = Observable.just(sections)
            .takeUntil(rx_deallocated)
            .bindTo(cv.rx_itemsWithDataSource(dataSource))
    }
}

extension ButtonCollectionViewCell {
    func update(occurrence occurrence: String) {
        label.text = occurrence
        label.backgroundColor = UIColor.flatOrangeColorDark()
    }
    
    func update(activeState activeState: EEvent) {
        label.text = "\(activeState.name) \(formatDuration(NSDate().timeIntervalSinceDate(activeState.date)))"
        label.backgroundColor = UIColor.flatGreenColorDark()
    }
    
    func update(state state: StateSchema) {
        label.text = state.icon
        label.backgroundColor = SyncManager.i().data().activeStates().contains { $0.name == state.name } ?
            UIColor.flatGreenColorDark() :
            UIColor.flatRedColorDark()
    }
    
    func update(reading reading: String) {
        label.text = reading
        label.backgroundColor = UIColor.flatBlueColorDark()
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
    
    override var highlighted: Bool {
        get { return super.highlighted }
        set {
            super.highlighted = newValue
            label?.backgroundColor = UIColor.randomFlatColor()
        }
    }
}
