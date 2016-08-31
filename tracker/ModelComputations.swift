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
        for e in events.reverse() {
            switch e.type! {
            case .StartState:
                if !endedStates.contains(e.name) {
                    retVal.append(e)
                }
            case .EndState:
                endedStates.insert(e.name)
            case .Reading: break
            case .Occurrence: break
            }
            if e.name == EVENT_SLEEP { break }
        }
        return retVal
    }

}