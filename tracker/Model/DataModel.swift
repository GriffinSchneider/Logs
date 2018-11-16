//
//  DataModel.swift
//  tracker
//
//  Created by Griffin on 12/4/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation

struct Data: Codable {
    var events: [Event] = []
}


enum EventType: String, Codable {
    case StartState = "StartState"
    case EndState = "EndState"
    case Reading = "Reading"
    case Occurrence = "Occurrence"
    case StreakExcuse = "StreakExcuse"
    case CreateTask = "CreateTask"
    case CompleteTask = "CompleteTask"
}

let EVENT_SLEEP = "Sleeping"

struct Event: Codable {
    var id: UUID
    var name: String
    var date: Date
    var type: EventType
    var link: UUID?
    var reading: Float?
    var note: String?
    init(
        id: UUID,
        name: String,
        date: Date,
        type: EventType,
        link: UUID? = nil,
        reading: Float? = nil,
        note: String? = nil
        ) {
        self.id = id
        self.name = name
        self.date = date
        self.type = type
        self.link = link
        self.reading = reading
        self.note = note
    }
}

func ==(lhs:Event, rhs:Event) -> Bool {
    return true &&
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.date == rhs.date &&
        lhs.type == rhs.type &&
        lhs.reading == rhs.reading &&
        lhs.note == rhs.note
}

func <(lhs:Event, rhs:Event) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedAscending
}

extension Event: Comparable { }

extension Event: Hashable {
    var hashValue: Int {
        var hash = id.hashValue ^ name.hashValue ^ date.hashValue ^ type.hashValue
        if let r = reading {
            hash = hash ^ r.hashValue
        }
        if let n = note {
            hash = hash ^ n.hashValue
        }
        return hash
    }
}
