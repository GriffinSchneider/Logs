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


struct SStateSchema: Mappable {
    var name: String!
    var icon: String!
    init?(map: Map) { }
    mutating func mapping(map: Map) {
        name <- map["name"]
        icon <- map["icon"]
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


struct OccurrenceSchema: Mappable {
    var name: String!
    init?(map: Map) { }
    mutating func mapping(map: Map) {
        name <- map["name"]
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


struct ReadingSchema: Mappable {
    var name: String!
    init?(map: Map) { }
    mutating func mapping(map: Map) {
        name <- map["name"]
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
