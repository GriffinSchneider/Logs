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
    var occurrences: [OccurrenceSchema] = []
    var states: [SStateSchema] = []
    var readings: [ReadingSchema] = []
    init?(map: Map) { }
    mutating func mapping(map: Map) {
        occurrences <- map["occurrences"]
        states <- map["states"]
        readings <- map["readings"]
    }
}


struct SStateSchema: Mappable, Streakable {
    var name: String!
    var icon: String!
    var streak: StreakSchema?
    init?(map: Map) { }
    mutating func mapping(map: Map) {
        name <- map["name"]
        icon <- map["icon"]
        streak <- map["streak"]
    }
}

extension SStateSchema: Hashable {
    var hashValue: Int {
        return name.hashValue ^ icon.hashValue
    }
}

func ==(lhs: SStateSchema, rhs: SStateSchema) -> Bool {
    return true &&
        lhs.name == rhs.name &&
        lhs.icon == rhs.icon
}


struct OccurrenceSchema: Mappable, Streakable {
    var name: String!
    var streak: StreakSchema?
    init?(map: Map) { }
    mutating func mapping(map: Map) {
        name <- map["name"]
        streak <- map["streak"]
    }
}

extension OccurrenceSchema: Hashable {
    var hashValue: Int {
        return name.hashValue
    }
}

func ==(lhs: OccurrenceSchema, rhs: OccurrenceSchema) -> Bool {
    return lhs.name == rhs.name
}


struct ReadingSchema: Mappable, Streakable {
    var name: String!
    var streak: StreakSchema?
    init?(map: Map) { }
    mutating func mapping(map: Map) {
        name <- map["name"]
        streak <- map["streak"]
    }
}

extension ReadingSchema: Hashable {
    var hashValue: Int {
        return name.hashValue
    }
}

func ==(lhs: ReadingSchema, rhs: ReadingSchema) -> Bool {
    return lhs.name == rhs.name
}


struct StreakSchema: Mappable {
    var perDay: Int = 1
    var interval: Int = 0
    init?(map: Map) { }
    mutating func mapping(map: Map) {
        perDay <- map["perDay"]
        interval <- map["interval"]
    }
}

protocol Streakable {
    var streak: StreakSchema? { get }
}

extension Streakable {
    var hasStreak: Bool { return streak != nil }
}
