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
    case occurrence(OccurrenceSchema)
    case activeState(SEvent)
    case state(SStateSchema, isActive: Bool)
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
    default:
        return false
    }
}

class SwiftViewController: UIViewController {
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        
        view.backgroundColor = UIColor.flatNavyBlueColorDark()
        
        let gridView = view.addSubview(ButtonGridView<SectionValue>() { b, data in
            Style.ButtonLabel(b)
            switch data {
            case let .action(s, _):
                b.setTitle(s, for: .normal)
                b.backgroundColor = UIColor.flatPlum()
            case let .occurrence(s):
                b.setTitle(s.name, for: .normal)
                b.backgroundColor = UIColor.flatOrangeColorDark()
            case let .activeState(a):
                b.setTitle("\(a.name!) \(formatDuration(Date().timeIntervalSince(a.date))!)" , for: .normal)
                b.backgroundColor = UIColor.flatGreenColorDark()
            case let .state(s, ia):
                b.setTitle(s.icon, for: .normal)
                b.backgroundColor = ia ? UIColor.flatGreenColorDark() : UIColor.flatRedColorDark()
                b.titleLabel?.font = UIFont.systemFont(ofSize: 32)
            }
            b.highlightedBackgroundColor = b.backgroundColor?.darken(byPercentage: 0.4)
        }) { v, make in
            v.backgroundColor = UIColor.flatNavyBlueColorDark()
            make.edges.equalTo(v.superview!)
        }
        
        let topActions: [SectionValue] = [
            .action("Edit") {
                self.present(UINavigationController(rootViewController: ListViewController() {
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
                let ac = UIAlertController(title: "u sure bro?", message: nil, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "yeah bro", style: .default) { _ in
                    let ac = UIAlertController(title: "rly tho?", message: nil, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "yeeeeeeeeeee", style: .default) { _ in
                        SyncManager.i().loadFromDropbox()
                    })
                    ac.addAction(UIAlertAction(title: "NOPE", style: .cancel) { _ in })
                    self.present(ac, animated: true)
                })
                ac.addAction(UIAlertAction(title: "nah bro", style: .cancel) { _ in })
                self.present(ac, animated: true)
            },
            .action("Save") {
                 SyncManager.i().writeToDropbox()
            },
        ]
        
        let bottomActions: [SectionValue] = [
            .action("Reading") {
                let vc = ReadingViewController {
                    $0.forEach {
                        SSyncManager.data.value.events.sortedAppend(SEvent(
                            name: $0.key.name,
                            date: Date(),
                            type: .Reading,
                            reading: $0.value
                        ))
                    }
                    self.dismiss(animated: true)
                }
                vc.modalPresentationStyle = .overCurrentContext
                vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                self.present(vc, animated: true)
            }
        ]
        
        Observable
            .combineLatest(SSyncManager.data.asObservable(), SSyncManager.schema.asObservable()) { ($0, $1) }
            .map { t -> [[SectionValue]] in
                let data = t.0, schema = t.1
                let active = data.activeStates()
                return [
                    topActions,
                    schema.occurrences.map { .occurrence($0) },
                    active.map { .activeState($0) },
                    schema.states.map { s in
                        .state(s, isActive: active.contains { a in
                            s.name == a.name
                        })
                    },
                    bottomActions,
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
                        name: o.name,
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
                }
            }
            .filter { $0 != nil }.map { $0! }
            .subscribeNext { SSyncManager.data.value.events.sortedAppend($0) }
            .addDisposableTo(disposeBag)
    }
}
