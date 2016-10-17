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

let SPACING: CGFloat = 5.0
let SECTION_INSETS = UIEdgeInsets(top: 30, left: 10, bottom: 0, right: 10)
let BUTTON_INSETS = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

enum SectionValue {
    case action(String, () -> ())
    case occurrence(String)
    case activeState(SEvent)
    case state(SStateSchema, isActive: Bool)
    case reading(String)
}
extension SectionValue: Hashable {
    var hashValue: Int {
        switch self {
        case let .action(s, _):
            return s.hashValue
        case let .occurrence(s):
            return s.hashValue
        case let .activeState(s):
            return s.hashValue
        case let .state(s, _):
            return s.hashValue
        case let .reading(s):
            return s.hashValue
        }
    }
}
func ==(lhs: SectionValue, rhs: SectionValue) -> Bool {
    switch (lhs, rhs) {
    case let (.action(l, _), .action(r, _)):
        return l == r
    case let (.occurrence(l), .occurrence(r)):
        return l == r
    case let (.activeState(l), .activeState(r)):
        return l == r
    case let (.state(l, _), .state(r, _)):
        return l == r
    case let (.reading(l), .reading(r)):
        return l == r
    default:
        return false
    }
}

class SwiftViewController: UIViewController {
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        
//        SyncManager.i().loadFromDropbox();
//        return
        
        view.backgroundColor = UIColor.flatNavyBlueColorDark()
        
        let gridView = view.addSubview(ButtonGridView<SectionValue>() { b, data in
            Style.ButtonLabel(b)
            switch data {
            case let .action(s, _):
                b.setTitle(s, for: .normal)
                b.backgroundColor = UIColor.flatPlum()
            case let .occurrence(s):
                b.setTitle(s, for: .normal)
                b.backgroundColor = UIColor.flatOrangeColorDark()
            case let .activeState(a):
                b.setTitle("\(a.name!) \(formatDuration(Date().timeIntervalSince(a.date))!)" , for: .normal)
                b.backgroundColor = UIColor.flatGreenColorDark()
            case let .state(s, ia):
                b.setTitle(s.name, for: .normal)
                b.backgroundColor = ia ? UIColor.flatGreenColorDark() : UIColor.flatRedColorDark()
            case let .reading(r):
                b.setTitle(r, for: .normal)
                b.backgroundColor = UIColor.blue
            }
        }) { v, make in
            v.backgroundColor = UIColor.flatNavyBlueColorDark()
            make.edges.equalTo(v.superview!)
        }
        
        let actions: [SectionValue] = [
            .action("Edit") {
                SyncManager.i().loadFromDisk()
                self.present(UINavigationController(rootViewController: ListViewController {
                    self.dismiss(animated: true)
                }), animated: true)
            },
            .action("Timeline") {
                SyncManager.i().loadFromDisk()
                self.present(TimelineViewController {
                    self.dismiss(animated: true)
                }, animated: true)
            },
            .action("Reload") {
                SyncManager.i().loadFromDropbox()
            },
            .action("Save") { print("sdfsdfdf") },
        ]
        
        Observable
            .combineLatest(SSyncManager.data.asObservable(), SSyncManager.schema.asObservable()) { ($0, $1) }
            .map { t -> [[SectionValue]] in
                let data = t.0, schema = t.1
                let active = data.activeStates()
                return [
                    actions,
                    schema.occurrences.map { .occurrence($0) },
                    active.map { .activeState($0) },
                    schema.states.map { s in
                        .state(s, isActive: active.contains { a in
                            s.name == a.name
                        })
                    },
                    schema.readings.map { .reading($0) }
                ]
            }
            .bindTo(gridView.buttons)
            .addDisposableTo(disposeBag)
        
        gridView
            .selection
            .map { v -> SEvent? in
                switch v {
                case let .action(_, b):
                    b()
                    return nil
                case let .occurrence(o):
                    return SEvent(
                        name: o,
                        date: Date(),
                        type: .Occurrence
                    )
                case let .activeState(s):
                    return SEvent(
                        name: s.name,
                        date: Date(),
                        type: .EndState
                    )
                case let .state((s, isActive)):
                    return SEvent(
                        name: s.name,
                        date: Date(),
                        type: isActive ? .EndState : .StartState
                    )
                case let .reading(r):
                    return nil
                }
            }
            .filter { $0 != nil }.map { $0! }
            .subscribeNext { SSyncManager.data.value.events.sortedAppend($0) }
            .addDisposableTo(disposeBag)
    }
}
