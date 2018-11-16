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
import NotificationCenter

let SPACING: CGFloat = 5.0
let SECTION_INSETS = UIEdgeInsets(top: 30, left: 10, bottom: 0, right: 10)
let BUTTON_INSETS = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

enum SectionValue {
    case action(String, () -> ())
    case occurrence(OccurrenceSchema)
    case activeState(Event)
    case state(StateSchema, isActive: UUID?)
    indirect case streak(StreakStatus, val: SectionValue)
    case task(Event)
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
        case let .task(e):
            return e.hashValue
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
    case let (.task(l), .task(r)):
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
        case let .task(e):
            return e.name
        }
    }
}

private func valToEvent(_ v: SectionValue) -> Event? {
    switch v {
    case .action:
        return nil
    case let .occurrence(o):
        return Event(
            id: UUID(),
            name: o.name,
            date: Date(),
            type: .Occurrence
        )
    case let .activeState(s):
        return Event(
            id: UUID(),
            name: s.name,
            date: Date(),
            type: .EndState,
            link: s.id
        )
    case let .state((s, isActive)):
        return Event(
            id: UUID(),
            name: s.name,
            date: Date(),
            type: isActive != nil ? .EndState : .StartState,
            link: isActive
        )
    case let .streak((_, val)):
        return valToEvent(val)
    case let .task(e):
        return Event(
            id: UUID(),
            name: e.name,
            date: Date(),
            type: .CompleteTask,
            link: e.id
        )

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

private func configure(button b: UIButton, forSectionValue data: SectionValue) {
    Style.ButtonLabel(b)
    switch data {
    case let .action(s, _):
        b.setTitle(s, for: .normal)
        b.backgroundColor = EventType.readingColor
    case let .occurrence(s):
        b.setTitle(s.name, for: .normal)
        b.backgroundColor = EventType.occurrenceColor
    case let .activeState(a):
        var icon = SyncManager.schema.value.icon(for: a)
        if icon == "" { icon = a.name }
        b.setTitle("\(icon) \(formatDuration(Date().timeIntervalSince(a.date))!)" , for: .normal)
        b.backgroundColor = EventType.streakColor
    case let .state(s, ia):
        b.setTitle(s.icon, for: .normal)
        b.backgroundColor = ia != nil ? EventType.streakColor : EventType.stateColor
        b.titleLabel?.font = UIFont.systemFont(ofSize: 32)
    case let .streak(s, v):
        b.backgroundColor = s.numberNeededToday > 0 ? EventType.streakExcuseColor : EventType.streakColor
        b.titleLabel?.numberOfLines = 0
        b.titleLabel?.textAlignment = .center
        let title = NSMutableAttributedString(
            string: "\(s.count)",
            attributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.flatWhite()
            ]
        )
        title.append(NSAttributedString(
            string: "\n\(v.name)" + (s.numberNeededToday > 0 ? " (\(s.numberNeededToday))" : ""),
            attributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .light),
                .foregroundColor: UIColor.flatWhite().withAlphaComponent(0.8)
            ]
        ))
        b.setAttributedTitle(title, for: .normal)
    case let .task(e):
        b.setTitle(e.name, for: .normal)
        b.backgroundColor = EventType.taskColor
    }
    b.setHighlightedBackgroundColor(b.backgroundColor?.darken(byPercentage: 0.4))
}

class MainViewController: UIViewController {
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        view.backgroundColor = UIColor.flatNavyBlueColorDark()
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        preferredContentSize = CGSize(width: self.view.frame.size.width, height: 600)

        let gridView = view.addSubview(ButtonGridView<SectionValue>() { b, v in
            configure(button: b, forSectionValue: v)
        }) { v, make in
            v.backgroundColor = UIColor.flatNavyBlueColorDark()
            make.edges.equalTo(v.superview!.safeAreaLayoutGuide)
        }
        
        let topActions: [SectionValue] = [
            .action("Edit") {
                self.present(UINavigationController(rootViewController: ListViewController() {
                    self.dismiss(animated: true)
                }), animated: true)
            },
            .action("Reload") {
                let ac = UIAlertController(title: "u sure bro?", message: nil, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "yeah bro", style: .default) { _ in
                    let ac = UIAlertController(title: "rly tho?", message: nil, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "yeeeeeeeeeee", style: .default) { _ in
                        SyncManager.download()
                    })
                    ac.addAction(UIAlertAction(title: "NOPE", style: .cancel) { _ in })
                    self.present(ac, animated: true)
                })
                ac.addAction(UIAlertAction(title: "nah bro", style: .cancel) { _ in })
                self.present(ac, animated: true)
            },
            .action("Save") {
                SyncManager.upload()
            },
        ]
        
        let bottomActions: [SectionValue] = [
            .action("Reading") {
                self.doReading()
            }
        ]
        let taskActions: [SectionValue] = [
            .action("New Task") {
                self.addAndEdit(event: Event(id: UUID(), name: "", date: Date(), type: .CreateTask))
            }
        ]
        
        Observable
            .combineLatest(SyncManager.data.asObservable(), SyncManager.schema.asObservable()) { ($0, $1) }
            .observeOn(MainScheduler.asyncInstance)
            .map { t -> [[SectionValue]] in
                let data = t.0, schema = t.1
                let active = data.activeStates()
                let occurrences: [SectionValue] = schema.occurrences.map { .occurrence($0) }
                let states: [SectionValue] = schema.states.map { s in
                    .state(s, isActive: active.first { a in s.name == a.name }?.id)
                }
                let streaks = occurrences.filter {$0.hasStreak} + states.filter {$0.hasStreak}
                let tasks = data.openTasks()
                
                return [
                    topActions,
                ] + tasks.map { [.task($0)] } + [
                    taskActions,
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
            .bind(to: gridView.buttons)
            .disposed(by: disposeBag)
        
        gridView
            .selection
            .observeOn(MainScheduler.instance)
            .map { sel -> (UIButton, SectionValue) in
                execVal(sel.1)
                return sel
            }
            .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "Background"))
            .map { sel -> ((UIButton, SectionValue), Event?, [Data.Suggestion]) in
                
                let event = valToEvent(sel.1)
                let needsSuggs = event != nil && event?.type != .EndState
                let suggs = needsSuggs ? SyncManager.data.value
                    .noteSuggestions(forEventNamed: event?.name, filterExcuses: true)
                    .filter { $0.count > 1 } : []
                if let e = event, suggs.count == 0 { SyncManager.data.value.events.sortedAppend(e) }
                return (sel, event, suggs)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { sel, event, suggs in
                guard suggs.count > 0 else { return }
                popover(
                    inView: self.view,
                    onButton: sel.0,
                    disposeBag: self.disposeBag,
                    buttons: suggs.map { sugg in
                        PopoverButtonInfo(
                            title: sugg.text ?? "",
                            config: { $0.backgroundColor = EventType.stateColor },
                            tap: {
                                guard var event = event else { return }
                                event.note = sugg.text
                                SyncManager.data.value.events.sortedAppend(event)
                            }
                        )
                    },
                    barButtons: [PopoverButtonInfo(
                        title: "Edit",
                        config: { $0.backgroundColor = EventType.readingColor },
                        tap: {
                            guard let event = event else { return }
                            self.addAndEdit(event: event)
                        }
                    ), PopoverButtonInfo(
                        title: "Add",
                        config: { $0.backgroundColor = EventType.readingColor },
                        tap: {
                            guard let event = event else { return }
                            SyncManager.data.value.events.sortedAppend(event)
                        }
                    )]
                )
            }).disposed(by: disposeBag)
        
        gridView
            .longPress
            .map { (b: UIButton, val: SectionValue) -> (UIButton, [PopoverButtonInfo]) in
                var actions =  [PopoverButtonInfo]()
                if let event = valToEvent(val) {
                    actions.append(PopoverButtonInfo(
                        title: "Add + Edit",
                        config: { $0.backgroundColor = EventType.readingColor },
                        tap: { self.addAndEdit(event: event) }
                    ))
                }
                switch val {
                case let .streak(_, val):
                    actions.append(PopoverButtonInfo(
                        title:"Extenuating Circumstances",
                        config: { $0.backgroundColor = EventType.streakExcuseColor },
                        tap: {
                            let event = valToEvent(val)
                            let newEvent = Event(id: UUID(), name: event!.name, date: Date(), type: .StreakExcuse)
                            SyncManager.data.value.events.sortedAppend(newEvent)
                        }
                    ))
                default:
                    break
                }
                return (b, actions)
            }
            .subscribe(onNext: { (b, buttons) in
                popover(inView: self.view, onButton: b, disposeBag: self.disposeBag, buttons: buttons)
            })
            .disposed(by: disposeBag)
    }
    
    public func addAndEdit(event: Event) {
        self.present(UINavigationController(rootViewController: EventViewController(event: event, done: {[weak self] newEvent in
            if let newEvent = newEvent, newEvent != event {
                SyncManager.data.value.events.sortedAppend(newEvent)
            }
            self?.dismiss(animated: true)
        })), animated: true)
    }
    
    public func doReading() {
        let vc = ReadingViewController {
            $0.forEach {
                SyncManager.data.value.events.sortedAppend(Event(
                    id: UUID(),
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
