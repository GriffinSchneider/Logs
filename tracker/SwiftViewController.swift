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
import Popover
import Toast

let SPACING: CGFloat = 5.0
let SECTION_INSETS = UIEdgeInsets(top: 30, left: 10, bottom: 0, right: 10)
let BUTTON_INSETS = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

enum SectionValue {
    case action(String, () -> ())
    case occurrence(OccurrenceSchema)
    case activeState(SEvent)
    case state(SStateSchema, isActive: Bool)
    indirect case streak(StreakStatus, val: SectionValue)
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
        case let .streak(_, v):
            return v.hashValue
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
    case let (.streak(_, l), .streak(_, r)):
        return l == r
    default:
        return false
    }
}
extension SectionValue {
    var hasStreak: Bool {
        switch self {
        case let .occurrence(s):
            return s.hasStreak
        case let .state(s, _):
            return s.hasStreak
        case .streak:
            return true
        default:
            return false
        }
    }
    var streak: StreakSchema {
        switch self {
        case let .occurrence(s):
            return s.streak!
        case let .state(s, _):
            return s.streak!
        case let .streak(_, val):
            return val.streak
        default:
            fatalError("No streak for \(self)")
        }
    }
    var name: String {
        switch self {
        case let .action(s, _):
            return s
        case let .occurrence(s):
            return s.name
        case let .activeState(s):
            return s.name
        case let .state(s, _):
            return s.name
        case let .streak(_, v):
            return v.name
        }
    }
}

class SwiftViewController: UIViewController {
    let disposeBag = DisposeBag()
    
    private func valToEvent(_ v: SectionValue) -> SEvent? {
        switch v {
        case .action:
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
        case let .streak((_, val)):
            return valToEvent(val)
        }
    }
    
    @discardableResult private func execVal(_ v: SectionValue) -> Bool {
        switch v {
        case let .action(_, b):
            b()
            return true
        default:
            return false
        }
    }
    
    
    override func viewDidLoad() {
        
        view.backgroundColor = UIColor.flatNavyBlueColorDark()
        
        let gridView = view.addSubview(ButtonGridView<SectionValue>() { b, data in
            Style.ButtonLabel(b)
            switch data {
            case let .action(s, _):
                b.setTitle(s, for: .normal)
                b.backgroundColor = SEventType.readingColor
            case let .occurrence(s):
                b.setTitle(s.name, for: .normal)
                b.backgroundColor = SEventType.occurrenceColor
            case let .activeState(a):
                b.setTitle("\(a.name!) \(formatDuration(Date().timeIntervalSince(a.date))!)" , for: .normal)
                b.backgroundColor = SEventType.streakColor
            case let .state(s, ia):
                b.setTitle(s.icon, for: .normal)
                b.backgroundColor = ia ? SEventType.streakColor : SEventType.stateColor
                b.titleLabel?.font = UIFont.systemFont(ofSize: 32)
            case let .streak(s, v):
                b.backgroundColor = s.numberNeededToday > 0 ? SEventType.streakExcuseColor : SEventType.streakColor
                b.titleLabel?.numberOfLines = 0
                b.titleLabel?.textAlignment = .center
                let title = NSMutableAttributedString(
                    string: "\(s.count)",
                    attributes: [
                        NSFontAttributeName: UIFont.systemFont(ofSize: 24, weight: UIFontWeightBold),
                        NSForegroundColorAttributeName: UIColor.flatWhite()
                    ]
                )
                title.append(NSAttributedString(
                    string: "\n\(v.name)" + (s.numberNeededToday > 0 ? " (\(s.numberNeededToday))" : ""),
                    attributes: [
                        NSFontAttributeName: UIFont.systemFont(ofSize: 10, weight: UIFontWeightLight),
                        NSForegroundColorAttributeName: UIColor.flatWhite().withAlphaComponent(0.8)
                    ]
                ))
                b.setAttributedTitle(title, for: .normal)
            }
            b.setHighlightedBackgroundColor(b.backgroundColor?.darken(byPercentage: 0.4))
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
        
        var stack = [SEvent]()
        
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
            },
            .action("Pop") {
                let last = SSyncManager.data.value.events.removeLast()
                stack.append(last)
                self.view.makeToast(
                    "⤴️ \(SSyncManager.schema.value.spacedIcon(for: last))\(last.name!)",
                    duration: 1,
                    position: CSToastPositionCenter
                )
            },
            .action("Push") {
                if let last = stack.popLast() {
                    SSyncManager.data.value.events.sortedAppend(last)
                    self.view.makeToast(
                        "⤵️ \(SSyncManager.schema.value.spacedIcon(for: last))\(last.name!)",
                        duration: 1,
                        position: CSToastPositionCenter
                    )
                } else {
                    self.view.makeToast(
                        "¯\\_(ツ)_/¯",
                        duration: 1,
                        position: CSToastPositionCenter
                    )
                }
            }
        ]
        
        Observable
            .combineLatest(SSyncManager.data.asObservable(), SSyncManager.schema.asObservable()) { ($0, $1) }
            .map { t -> [[SectionValue]] in
                let data = t.0, schema = t.1
                let active = data.activeStates()
                let occurrences: [SectionValue] = schema.occurrences.map { .occurrence($0) }
                let states: [SectionValue] = schema.states.map { s in
                    .state(s, isActive: active.contains { a in
                        s.name == a.name
                    })
                }
                let streaks = occurrences.filter {$0.hasStreak} + states.filter {$0.hasStreak}
                
                return [
                    topActions,
                    streaks.map {
                        .streak(data.status(
                            forStreak: $0.streak,
                            named: $0.name
                        ), val: $0)
                    },
                    occurrences.filter { !$0.hasStreak },
                    active.map { .activeState($0) },
                    states.filter { !$0.hasStreak },
                    bottomActions,
                ]
            }
            .bindTo(gridView.buttons)
            .addDisposableTo(disposeBag)
        
        gridView
            .selection
            .map { self.execVal($0) ; return self.valToEvent($0) }
            .filter { $0 != nil }.map { $0! }
            .subscribe(onNext: { SSyncManager.data.value.events.sortedAppend($0) })
            .addDisposableTo(disposeBag)
        
        gridView
            .longPress
            .map { (b: UIButton, val: SectionValue) -> (UIButton, [(String, UIColor, () -> Void)]) in
                var actions: [(String, UIColor, () -> Void)]
                switch val {
                case let .streak(_, val):
                    actions = [
                        ("Extenuating Circumstances", SEventType.streakExcuseColor ,{
                            let event = self.valToEvent(val)
                            let newEvent = SEvent(name: event!.name, date: Date(), type: .StreakExcuse)
                            SSyncManager.data.value.events.sortedAppend(newEvent)
                        })
                    ]
                default:
                    actions = []
                }
                if let event = self.valToEvent(val) {
                    actions.append(("Add + Edit", SEventType.readingColor ,{
                        self.present(UINavigationController(rootViewController: EventViewController(event: event, done: {[weak self] newEvent in
                            if let e = newEvent {
                                SSyncManager.data.value.events.sortedAppend(e)
                            }
                            self?.dismiss(animated: true)
                        })), animated: true)
                    }))
                }
                return (b, actions)
            }
            .subscribe(onNext: { (b, actions) in
                guard actions.count > 0 else {
                    return
                }
                let popover = Popover(options: [.color(UIColor.flatNavyBlueColorDark())])
                let view = UIView()
                view.frame = CGRect(x: 0, y: 0, width: 200, height: 0)
                actions.forEach { name, color, block in
                    let button = UIButton()
                    button.titleLabel?.lineBreakMode = .byWordWrapping
                    button.titleLabel?.textAlignment = .center
                    button.titleLabel?.numberOfLines = 0
                    button.setTitle(name, for: .normal)
                    button.backgroundColor = color
                    Style.ButtonLabel(button)
                    let size = NSString(string: name) .boundingRect(
                        with: CGSize(width: view.frame.size.width - 10, height: 9999),
                        options: .usesLineFragmentOrigin,
                        attributes: [NSFontAttributeName: button.titleLabel!.font],
                        context: nil
                    )
                    button.frame.size = size.size
                    let y: CGFloat
                    if let last = view.subviews.last {
                        y =  last.frame.origin.y + last.frame.size.height + 5
                    } else {
                        y = 5
                    }
                    button.frame = CGRect(
                        x: 5,
                        y: y,
                        width: view.frame.size.width - 10,
                        height: button.frame.size.height
                    )
                    button.rx.tap.subscribe(onNext: {
                        block()
                        popover.dismiss()
                    }).addDisposableTo(self.disposeBag)
                    view.addSubview(button)
                }
                let last = view.subviews.last!
                view.frame = CGRect(x: 0, y: 0, width: 200, height: last.frame.origin.y + last.frame.size.height + 5)
                popover.show(view, fromView: b, inView: self.view)
            })
            .addDisposableTo(disposeBag)
    }
}
