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
                        SSyncManager.download()
                    })
                    ac.addAction(UIAlertAction(title: "NOPE", style: .cancel) { _ in })
                    self.present(ac, animated: true)
                })
                ac.addAction(UIAlertAction(title: "nah bro", style: .cancel) { _ in })
                self.present(ac, animated: true)
            },
            .action("Save") {
                SSyncManager.upload()
            },
        ]
        
        let bottomActions: [SectionValue] = [
            .action("Reading") {
                self.doReading()
            }
        ]
        
        Observable
            .combineLatest(SSyncManager.data.asObservable(), SSyncManager.schema.asObservable()) { ($0, $1) }
            .observeOn(MainScheduler.asyncInstance)
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
            .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "Background"))
            .map { sel -> ((UIButton, SectionValue), SEvent?, [SData.Suggestion]) in
                self.execVal(sel.1)
                let event = self.valToEvent(sel.1)
                let needsSuggs = event != nil && event?.type != .EndState
                let suggs = needsSuggs ? SSyncManager.data.value
                    .noteSuggestions(forEventNamed: event?.name!, filterExcuses: true)
                    .filter { $0.count > 1 } : []
                if let e = event, suggs.count == 0 { SSyncManager.data.value.events.sortedAppend(e) }
                return (sel, event, suggs)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { sel, event, suggs in
                guard suggs.count > 0 else { return }
                
                popover(inView: self.view, onButton: sel.0, withBag: self.disposeBag, withButtons:
                    [PopoverButtonInfo(
                        title: "Add",
                        config: { $0.backgroundColor = SEventType.streakExcuseColor },
                        tap: {
                            guard let event = event else { return }
                            SSyncManager.data.value.events.sortedAppend(event)
                        }
                    )] +
                    suggs.map { sugg in
                        PopoverButtonInfo(
                            title: sugg.text ?? "",
                            config: { $0.backgroundColor = SEventType.streakColor },
                            tap: {
                                guard var event = event else { return }
                                event.note = sugg.text
                                SSyncManager.data.value.events.sortedAppend(event)
                            }
                        )
                    })
            }).addDisposableTo(disposeBag)
        
        gridView
            .longPress
            .map { (b: UIButton, val: SectionValue) -> (UIButton, [PopoverButtonInfo]) in
                var actions =  [PopoverButtonInfo]()
                if let event = self.valToEvent(val) {
                    actions.append(PopoverButtonInfo(
                        title: "Add + Edit",
                        config: { $0.backgroundColor = SEventType.readingColor },
                        tap: {
                            self.present(UINavigationController(rootViewController: EventViewController(event: event, done: {[weak self] newEvent in
                                if let e = newEvent {
                                    SSyncManager.data.value.events.sortedAppend(e)
                                }
                                self?.dismiss(animated: true)
                            })), animated: true)
                        }
                    ))
                }
                switch val {
                case let .streak(_, val):
                    actions.append(PopoverButtonInfo(
                        title:"Extenuating Circumstances",
                        config: { $0.backgroundColor = SEventType.streakExcuseColor },
                        tap: {
                            let event = self.valToEvent(val)
                            let newEvent = SEvent(name: event!.name, date: Date(), type: .StreakExcuse)
                            SSyncManager.data.value.events.sortedAppend(newEvent)
                        }
                    ))
                default:
                    break
                }
                return (b, actions)
            }
            .subscribe(onNext: { (b, buttons) in
                popover(inView: self.view, onButton: b, withBag: self.disposeBag, withButtons: buttons)
            })
            .addDisposableTo(disposeBag)
    }
    
    public func doReading() {
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
}
