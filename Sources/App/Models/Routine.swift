//
//  Routine.swift
//  FYP-APIPackageDescription
//
//  Created by Ben Kovacs on 2018-03-12.
//

import Foundation
import Vapor
import FluentProvider
import HTTP

final class Routine: Model {
    let storage = Storage()
    
    var name: String
    var ownerId: String
    var weekId: String
    
    struct Keys {
        static let id = "id"
        static let name = "name"
        static let ownerId = "ownerId"
        static let weekId = "weekId"
    }
    
    init(name: String, ownerId: String, weekId: String) {
        self.name = name
        self.ownerId = ownerId
        self.weekId = weekId
    }
    
    
    init(row: Row) throws {
        self.name = try row.get(Keys.name)
        self.weekId = try row.get(Keys.weekId)
        self.ownerId = try row.get(Keys.ownerId)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Keys.name, name)
        try row.set(Keys.weekId, weekId)
        try row.set(Keys.ownerId, ownerId)
        return row
    }
}

extension Routine: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Keys.name)
            builder.int(Keys.ownerId)
            builder.int(Keys.weekId)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Routine: JSONConvertible {
    convenience init(json: JSON) throws {
        
        try self.init(
            name: json.get(Keys.name),
            ownerId: json.get(Keys.ownerId),
            weekId: json.get(Keys.weekId)
        )
        id = try json.get(Keys.id)
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Keys.id, id)
        try json.set(Keys.weekId, weekId)
        try json.set(Keys.ownerId, ownerId)
        return json
    }
}

extension Routine: ResponseRepresentable { }

extension Routine: Updateable {
    static var updateableKeys: [UpdateableKey<Routine>] {
        return [
            UpdateableKey(Routine.Keys.name) { routine, name in
                routine.name = name
            },
            UpdateableKey(Routine.Keys.ownerId){ routine, id in
                routine.ownerId = id
            },
            UpdateableKey(Routine.Keys.weekId) { routine, id in
                routine.weekId = id
            }
        ]
    }
    
    
}


