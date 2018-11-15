//
//  Model.swift
//  tracker
//
//  Created by Griffin Schneider on 8/31/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation

protocol Iconable {
    var name: String { get }
    var icon: String? { get }
}

struct Schema: Codable {
    var occurrences: [OccurrenceSchema] = []
    var states: [StateSchema] = []
    var readings: [ReadingSchema] = []
}


struct StateSchema: Codable, Streakable, Iconable {
    var name: String
    var icon: String?
    var streak: StreakSchema?
}

extension StateSchema: Hashable {
    var hashValue: Int {
        return name.hashValue ^ icon.hashValue
    }
}

func ==(lhs: StateSchema, rhs: StateSchema) -> Bool {
    return true &&
        lhs.name == rhs.name &&
        lhs.icon == rhs.icon
}


struct OccurrenceSchema: Codable, Streakable, Iconable {
    var name: String
    var icon: String?
    var streak: StreakSchema?
}

extension OccurrenceSchema: Hashable {
    var hashValue: Int {
        return name.hashValue
    }
}

func ==(lhs: OccurrenceSchema, rhs: OccurrenceSchema) -> Bool {
    return lhs.name == rhs.name
}


struct ReadingSchema: Codable, Streakable, Iconable {
    var name: String
    var icon: String?
    var streak: StreakSchema?
}

extension ReadingSchema: Hashable {
    var hashValue: Int {
        return name.hashValue
    }
}

func ==(lhs: ReadingSchema, rhs: ReadingSchema) -> Bool {
    return lhs.name == rhs.name
}

extension KeyedDecodingContainer {
    fileprivate func decode(_ type: Int.Type, forKey key: KeyedDecodingContainer<K>.Key, default d: Int) -> Int {
        let mayb = try? decodeIfPresent(type, forKey: key)
        return (mayb ?? d) ?? d
    }
}


struct StreakSchema: Codable {
    var perDay: Int
    var interval: Int
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.perDay = container.decode(Int.self, forKey: .perDay, default: 1)
        self.interval = container.decode(Int.self, forKey: .interval, default: 0)
    }
}

protocol Streakable {
    var streak: StreakSchema? { get }
    var name: String { get }
}

extension Streakable {
    var hasStreak: Bool { return streak != nil }
}
