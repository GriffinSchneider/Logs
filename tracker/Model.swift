//
//  Model.swift
//  tracker
//
//  Created by Griffin Schneider on 8/31/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import ObjectMapper


struct SSchema: Mappable {
    var occurrences: [String]!
    var states: [SStateSchema]!
    var readings: [String]!
    init?(_ map: Map) { }
    mutating func mapping(map: Map) {
        occurrences <- map["occurrences"]
        states <- map["states"]
        readings <- map["readings"]
    }
}


struct SStateSchema: Mappable {
    var name: String!
    var icon: String!
    init?(_ map: Map) { }
    mutating func mapping(map: Map) {
        name <- map["name"]
        icon <- map["icon"]
    }
}


struct SData: Mappable {
    var events: [SEvent]!
    init?(_ map: Map) { }
    mutating func mapping(map: Map) {
        events <- map["events"]
    }
}


enum SEventType: String {
    case StartState = "StartState"
    case EndState = "EndState"
    case Reading = "Reading"
    case Occurrence = "Occurrence"
}


struct SEvent: Mappable {
    var name: String!
    var date: NSDate!
    var type: SEventType!
    var reading: Float?
    var note: String?
    init?(_ map: Map) { }
    mutating func mapping(map: Map) {
        name <- map["name"]
        date <- (map["date"], StringDateJSONTransform())
        type <- (map["type"], EnumTransform())
        reading <- map["reading"]
        note <- map["note"]
    }
}

func ==(lhs:SEvent, rhs:SEvent) -> Bool {
    return true &&
        lhs.name == rhs.name &&
        lhs.date == rhs.name &&
        lhs.type == rhs.type &&
        lhs.reading == rhs.reading &&
        lhs.note == rhs.note
}

extension SEvent: Hashable {
    var hashValue: Int {
        var hash = name.hashValue ^ date.hashValue ^ type.hashValue
        if let r = reading {
            hash = hash ^ r.hashValue
        }
        if let n = note {
            hash = hash ^ n.hashValue
        }
        return hash
    }
}