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
    let initialized: String
    let finalized: String
    let routineId: String
    
    struct Keys {
        static let id = "id"
        static let day = "day"
        static let empty = "empty"
        static let initialized = "initialized"
        static let finalized = "finalized"
        static let routineId = "routineId"
    }
    
    init(day: Int, empty: Bool, initialized: String, finalized: String, routineId: String) {
        self.day = day
        self.empty = empty
        self.initialized = initialized
        self.finalized = finalized
        self.routineId = routineId
    }
    
    init(row: Row) throws {
        self.day = try row.get(Keys.day)
        self.empty = try row.get(Keys.empty)
        self.initialized = try row.get(Keys.initialized)
        self.finalized = try row.get(Keys.finalized)
        self.routineId = try row.get(Keys.routineId)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Keys.day, day)
        try row.set(Keys.empty, empty)
        try row.set(Keys.initialized, initialized)
        try row.set(Keys.finalized, finalized)
        try row.set(Keys.routineId, routineId)
        return row
    }
}

extension RoutineDay: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.int(Keys.day)
            builder.string(Keys.initialized)
            builder.string(Keys.finalized)
            builder.bool(Keys.empty)
            builder.string(Keys.routineId)
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
            finalized: json.get(Keys.finalized),
            routineId: json.get(Keys.routineId)
        )
        id = try json.get(Keys.id)
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Keys.id, id)
        try json.set(Keys.empty, empty)
        try json.set(Keys.initialized, initialized)
        try json.set(Keys.finalized, finalized)
        try json.set(Keys.day, day)
        try json.set(Keys.routineId, routineId)
        return json
    }
}

extension RoutineDay: ResponseRepresentable { }


