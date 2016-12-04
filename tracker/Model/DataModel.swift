//
//  DataModel.swift
//  tracker
//
//  Created by Griffin on 12/4/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import ObjectMapper


struct SData: Mappable {
    var events: [SEvent] = []
    init?(map: Map) { }
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
    var date: Date!
    var type: SEventType!
    var reading: Float?
    var note: String?
    init?(map: Map) { }
    init(
        name: String,
        date: Date,
        type: SEventType,
        reading: Float? = nil,
        note: String? = nil
        ) {
        self.name = name
        self.date = date
        self.type = type
        self.reading = reading
        self.note = note
    }
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
        lhs.date == rhs.date &&
        lhs.type == rhs.type &&
        lhs.reading == rhs.reading &&
        lhs.note == rhs.note
}

func <(lhs:SEvent, rhs:SEvent) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedAscending
}

extension SEvent: Comparable { }

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
