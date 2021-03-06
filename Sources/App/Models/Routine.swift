//
//  Routine.swift
//  FYP-APIPackageDescription
//
//  Created by Ben Kovacs on 2018-03-12.
//

import Foundation
import Vapor
import FluentProvider
import AuthProvider
import HTTP

final class Routine: Model {
    let storage = Storage()
    
    var name: String
    var userIdKey: Identifier?
    
    struct Keys {
        static let id = "id"
        static let name = "name"
        static let userIdKey = "user_id"
    }
    
    init(name: String, userIdKey: Identifier? = nil) {
        self.name = name
        self.userIdKey = userIdKey
    }
    
    
    init(row: Row) throws {
        self.name = try row.get(Keys.name)
        self.userIdKey = try row.get(Keys.userIdKey)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Keys.name, name)
        try row.set(Keys.userIdKey, userIdKey)
        return row
    }
}

extension Routine: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Keys.name, optional: true)
            builder.foreignId(for: User.self, optional: true)
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
            userIdKey: json.get(Keys.userIdKey)
        )
        id = try json.get(Keys.id)
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Keys.id, id)
        try json.set(Keys.userIdKey, userIdKey)
        try json.set(Keys.name, name)
        return json
    }
}

extension Routine: ResponseRepresentable { }

extension Routine: Updateable {
    static var updateableKeys: [UpdateableKey<Routine>] {
        return [
            UpdateableKey(Routine.Keys.name) { routine, name in
                routine.name = name
            }
        ]
    }
}

extension Routine {
    
    var days: Children<Routine, RoutineDay> {
        return children()
    }
    
    var user: Parent<Routine, User> {
        return parent(id: self.userIdKey)
    }
}


