//
//  ModelComputations.swift
//  tracker
//
//  Created by Griffin Schneider on 8/31/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation


extension Data {
    /// A list of all the StartState events that don't have a corresponding EndState,
    /// sorted chronologically.
    func activeStates() -> [Event] {
        var retVal = [UUID: Event]()
        for e in events {
            switch e.type {
            case .StartState:
                if let link = e.link {
                    if retVal[link] == nil {
                        print("Found an un-linkable event: \(e)")
                        retVal[e.id] = e
                    } else {
                        // This StartState is 'starting' an already-started event, so it won't affect
                        // which states are active.
                    }
                } else {
                    retVal[e.id] = e
                }
            case .EndState:
                if let link = e.link, retVal[link] != nil {
                    retVal.removeValue(forKey: link)
                } else {
                    print("Found an un-linkable event: \(e)")
                }
            default: break
            }
        }
        return retVal.values.sorted { $0.date < $1.date }
    }
}

struct StreakStatus {
    var numberNeededToday: Int
    var count: Int
}

extension Data {
    func status(forStreak streak: StreakSchema, named name: String) -> StreakStatus {
        var retVal = StreakStatus(numberNeededToday: 0, count: 0)
        var daysSinceStreakCounterToday = -1
        var daysSinceStreakCounter = 0
        var countThisDay = 0
        var countToday = 0
        var excuseThisDay = false
        var excuseToday = false
        var isToday = true
        for e in events.reversed() {
            if e.name == EVENT_SLEEP && e.type == .StartState {
                
                if isToday || !excuseThisDay {
                    retVal.count += 1
                }
                if isToday {
                    countToday = countThisDay
                    excuseToday = excuseThisDay
                }
                if !isToday && daysSinceStreakCounterToday == -1 && countThisDay >= streak.perDay {
                    daysSinceStreakCounterToday = daysSinceStreakCounter
                }
                if countThisDay < streak.perDay && !isToday {
                    if !excuseThisDay {
                        daysSinceStreakCounter += 1
                    }
                } else if countThisDay >= streak.perDay {
                    daysSinceStreakCounter = 0
                }
                if daysSinceStreakCounter > streak.interval {
                    if daysSinceStreakCounterToday == -1 {
                        daysSinceStreakCounterToday = daysSinceStreakCounter
                    }
                    if daysSinceStreakCounterToday >= streak.interval && !excuseToday {
                        retVal.numberNeededToday = streak.perDay - countToday
                    }
                    retVal.count -= (streak.interval + 1)
                    if countToday < streak.perDay && daysSinceStreakCounterToday >= streak.interval {
                        retVal.count -= 1
                    }
                    return retVal
                }
                countThisDay = 0
                excuseThisDay = false
                isToday = false
                continue
            }
            switch e.type {
            case .StartState, .Reading, .Occurrence, .CompleteTask:
                if e.name == name {
                    countThisDay += 1
                }
            case .StreakExcuse:
                if e.name == name {
                    excuseThisDay = true
                }
            case .EndState, .CreateTask: break
            }
        }
        return retVal
    }
}

extension Data {
    func openTasks() -> [Event] {
        var retVal = [UUID: Event]()
        for e in events {
            switch e.type {
            case .CreateTask:
                if let overlap = retVal[e.id] { print("ID Overlap!\n\(e)\n\(overlap)") }
                retVal[e.id] = e
            case .CompleteTask:
                if let link = e.link { retVal.removeValue(forKey: link) }
            default: break
            }
        }
        return retVal.values.sorted { $0.date < $1.date }
    }
}

extension Data {
    struct Suggestion {
        let text: String?
        let count: Int
    }
    func noteSuggestions(forEventNamed eventName: String?, filterExcuses: Bool = false) -> [Suggestion] {
        guard let eventName = eventName else { return [] }
        let sugs = events
            .reversed()
            .filter { $0.name == eventName }
            .filter { !filterExcuses || $0.type != .StreakExcuse }
            .flatMap {(e: Event) -> [String?] in e.note?.components(separatedBy: "\n") ?? [] }
            .map { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !($0 == nil || $0!.isEmpty) }
        var freq: [String: Int] = [:]
        for s in sugs {
            freq[s!] = (freq[s!] ?? 0) + 1
        }
        return freq
            .sorted { l, r in l.value > r.value }
            .map { Suggestion(text: $0.key, count: $0.value) }
    }
}

extension Data {
    func event(forId id: UUID) -> Event? {
        return events.first { $0.id == id }
    }
}

extension Schema {
    func icon(for event: Event) -> String {
        if event.type == .CreateTask { return "📝" }
        if event.type == .CompleteTask { return "✅" }
        let stuff = occurrences as [Iconable] + states as [Iconable] + readings as [Iconable]
        return stuff.first(where: {
            $0.name == event.name
        })?.icon ?? ""
    }
    
    func spacedIcon(for event: Event) -> String {
        let icon = self.icon(for: event)
        if icon == "" {
            return icon   
        } else {
            return " \(icon)"
        }
    }
    
    func hasStreak(event: Event) -> Bool {
        let stuff = occurrences as [Streakable] + states as [Streakable] + readings as [Streakable]
        return stuff.first(where: {
            $0.name == event.name
        })?.hasStreak ?? false
    }
}

extension EventType {
    static let stateColor = UIColor.flatBlueColorDark()!.lighten(byPercentage: 0.1)!
    static let taskColor = UIColor.flatForestGreenColorDark()!.lighten(byPercentage: 0.1)!
    static let readingColor = UIColor.flatPlum()!.lighten(byPercentage: 0.05)!
    static let occurrenceColor = UIColor.flatOrangeColorDark()!.darken(byPercentage: 0.1)!
    static let streakColor = UIColor.flatGreenColorDark()!.darken(byPercentage: 0.1)!
    static let streakExcuseColor = UIColor.flatRedColorDark()!
    
    var color: UIColor {
        switch self {
        case .StartState, .EndState:
            return EventType.stateColor
        case .CreateTask, .CompleteTask:
            return EventType.taskColor
        case .Reading:
            return EventType.readingColor
        case .Occurrence:
            return EventType.occurrenceColor
        case .StreakExcuse:
            return EventType.streakExcuseColor
        }
    }
}

extension Event {
    var color: UIColor {
        if SyncManager.schema.value.hasStreak(event: self) && type != .StreakExcuse {
            return EventType.streakColor
        } else {
            return type.color
        }
    }
}
