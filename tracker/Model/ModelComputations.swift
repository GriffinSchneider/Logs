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
            case .Reading, .Occurrence: break
            }
            if e.name == EVENT_SLEEP { break }
        }
        return retVal
    }
}

struct StreakStatus {
    enum Needed {
        case neededToday
        case notNeeded
    }
    var needed: Needed
    var count: Int
}

extension SData {
    func status(forStreak streak: StreakSchema, named name: String) -> StreakStatus {
        var retVal = StreakStatus(needed: .neededToday, count: 0)
        var daysSinceStreakCounterToday = -1
        var daysSinceStreakCounter = 0
        var countThisDay = 0
        var countToday = 0
        var isToday = true
        for e in events.reversed() {
            if e.name == EVENT_SLEEP && e.type == .StartState {
                if isToday {
                    countToday = countThisDay
                }
                if countThisDay < streak.perDay && !isToday {
                    daysSinceStreakCounter += 1
                }
                if daysSinceStreakCounter > streak.interval {
                    if daysSinceStreakCounterToday == -1 {
                        daysSinceStreakCounterToday = daysSinceStreakCounter
                    }
                    if countToday < streak.perDay && daysSinceStreakCounterToday >= streak.interval {
                        retVal.needed = .neededToday
                    } else {
                        retVal.needed = .notNeeded
                    }
                    return retVal
                }
                countThisDay = 0
                isToday = false
                continue
            }
            switch e.type! {
            case .StartState, .Reading, .Occurrence:
                if e.name == name {
                    countThisDay += 1
                    if !isToday && daysSinceStreakCounterToday == -1 && countThisDay >= streak.perDay {
                        daysSinceStreakCounterToday = daysSinceStreakCounter
                    }
                    if isToday || countThisDay > streak.perDay {
                        retVal.count += 1
                    } else if countThisDay == streak.perDay {
                        retVal.count += streak.perDay
                    }
                }
            case .EndState: break
            }
        }
        return retVal
    }
}
