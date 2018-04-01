//
//  RoutineDay.swift
//  FYP-APIPackageDescription
//
//  Created by Ben Kovacs on 2018-03-12.
//

import Foundation
import Vapor
import FluentProvider
import HTTP

final class RoutineDay: Model {
    let storage = Storage()
    
    let day: Int
    let empty: Bool
    let initialized: String?
    let workoutId: String?
    var routineIdKey: Identifier?
    
    struct Keys {
        static let id = "id"
        static let day = "day"
        static let empty = "empty"
        static let initialized = "initialized"
        static let workoutId = "workoutId"
        static let routineId = "routine_id"
    }
    
    init(day: Int, empty: Bool, initialized: String? = nil, workoutId: String? = nil, routineIdKey: Identifier? = nil) {
        self.day = day
        self.empty = empty
        self.initialized = initialized
        self.workoutId = workoutId
        self.routineIdKey = routineIdKey
    }
    
    init(row: Row) throws {
        self.day = try row.get(Keys.day)
        self.empty = try row.get(Keys.empty)
        self.initialized = try row.get(Keys.initialized)
        self.workoutId = try row.get(Keys.workoutId)
        self.routineIdKey = try row.get(Keys.routineId)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Keys.day, day)
        try row.set(Keys.empty, empty)
        try row.set(Keys.initialized, initialized)
        try row.set(Keys.workoutId, workoutId)
        try row.set(Keys.routineId, routineIdKey)
        return row
    }
}

extension RoutineDay: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.int(Keys.day)
            builder.string(Keys.initialized, optional: true)
            builder.string(Keys.workoutId, optional: true)
            builder.bool(Keys.empty)
            builder.foreignId(for: Routine.self, optional: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension RoutineDay: JSONConvertible {
    convenience init(json: JSON) throws {
        
        try self.init(
            day: json.get(Keys.day),
            empty: json.get(Keys.empty),
            initialized: json.get(Keys.initialized),
            workoutId: json.get(Keys.workoutId),
            routineIdKey: json.get(Keys.routineId)
        )
        id = try json.get(Keys.id)
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Keys.id, id)
        try json.set(Keys.empty, empty)
        try json.set(Keys.initialized, initialized)
        try json.set(Keys.workoutId, workoutId)
        try json.set(Keys.day, day)
        try json.set(Keys.routineId, routineIdKey)
        return json
    }
}

extension RoutineDay: ResponseRepresentable { }

extension RoutineDay {
    var routine: Parent<RoutineDay, Routine> {
        return parent(id: self.routineIdKey, type: Routine.self)
    }
    
    var tags: Siblings<RoutineDay, WorkoutTag, Pivot<RoutineDay, WorkoutTag>> {
        return siblings()
    }
    
}


struct DayWrapper {
    let day: Int
    let empty: Bool
    let initialized: [String]?
    let workoutId: String?
    var routineIdKey: Identifier?
}

extension DayWrapper {
    init(json: JSON) throws {
        try self.init(
            day: json.get(RoutineDay.Keys.day),
            empty: json.get(RoutineDay.Keys.empty),
            initialized: json.get(RoutineDay.Keys.initialized),
            workoutId: json.get(RoutineDay.Keys.workoutId),
            routineIdKey: json.get(RoutineDay.Keys.routineId)
        )
    }
}

