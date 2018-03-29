//
//  MovementTag.swift
//  App
//
//  Created by Ben Kovacs on 2018-03-28.
//

import Foundation
import Vapor
import FluentProvider
import AuthProvider
import HTTP

final class MovementTag: Model {
    let storage = Storage()
    
    var name: String
    
    struct Keys {
        static let id = "id"
        static let name = "name"
    }
    
    init(name: String) {
        self.name = name
    }
    
    
    init(row: Row) throws {
        self.name = try row.get(Keys.name)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Keys.name, name)
        return row
    }
}

extension MovementTag: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Keys.name, optional: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension MovementTag: JSONConvertible {
    convenience init(json: JSON) throws {
        
        try self.init(
            name: json.get(Keys.name)
        )
        id = try json.get(Keys.id)
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Keys.id, id)
        try json.set(Keys.name, name)
        return json
    }
}

extension MovementTag: ResponseRepresentable { }

extension MovementTag: Updateable {
    
    static var updateableKeys: [UpdateableKey<MovementTag>] {
        return [
            UpdateableKey(MovementTag.Keys.name) { routine, name in
                routine.name = name
            }
        ]
    }
}

extension MovementTag {
    
}


