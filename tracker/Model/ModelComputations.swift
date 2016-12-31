//
//  ModelComputations.swift
//  tracker
//
//  Created by Griffin Schneider on 8/31/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation


extension SData {
    func activeStates() -> [SEvent] {
        var retVal = [SEvent]()
        var endedStates = Set<String>()
        for e in events.reversed() {
            switch e.type! {
            case .StartState:
                if !endedStates.contains(e.name) {
                    retVal.append(e)
                }
            case .EndState:
                endedStates.insert(e.name)
            case .Reading, .Occurrence, .StreakExcuse: break
            }
            if e.name == EVENT_SLEEP { break }
        }
        return retVal
    }
}

struct StreakStatus {
    var numberNeededToday: Int
    var count: Int
}

extension SData {
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
            switch e.type! {
            case .StartState, .Reading, .Occurrence:
                if e.name == name {
                    countThisDay += 1
                }
            case .StreakExcuse:
                if e.name == name {
                    excuseThisDay = true
                }
            case .EndState: break
            }
        }
        return retVal
    }
}

extension SSchema {
    func icon(for event: SEvent) -> String {
        let stuff = occurrences as [Iconable] + states as [Iconable] + readings as [Iconable]
        return stuff.first(where: {
            $0.name == event.name
        })?.icon ?? ""
    }
    
    func spacedIcon(for event: SEvent) -> String {
        let icon = self.icon(for: event)
        if icon == "" {
            return icon   
        } else {
            return " \(icon)"
        }
    }
    
    func hasStreak(event: SEvent) -> Bool {
        let stuff = occurrences as [Streakable] + states as [Streakable] + readings as [Streakable]
        return stuff.first(where: {
            $0.name == event.name
        })?.hasStreak ?? false
    }
}

extension SEventType {
    static let stateColor = UIColor.flatBlueColorDark()!
    static let readingColor = UIColor.flatPlum()!.lighten(byPercentage: 0.05)!
    static let occurrenceColor = UIColor.flatOrangeColorDark()!.darken(byPercentage: 0.1)!
    static let streakColor = UIColor.flatGreenColorDark()!.darken(byPercentage: 0.1)!
    static let streakExcuseColor = UIColor.flatRedColorDark()!
    
    var color: UIColor {
        switch self {
        case .StartState, .EndState:
            return SEventType.stateColor
        case .Reading:
            return SEventType.readingColor
        case .Occurrence:
            return SEventType.occurrenceColor
        case .StreakExcuse:
            return SEventType.streakExcuseColor
        }
    }
}

extension SEvent {
    var color: UIColor {
        if SSyncManager.schema.value.hasStreak(event: self) && type != .StreakExcuse {
            return SEventType.streakColor
        } else {
            return type.color
        }
    }
}
