//
//  Movement.swift
//  FYP-APIPackageDescription
//
//  Created by Ben Kovacs on 2018-02-27.
//

import Foundation
import Vapor
import FluentProvider
import HTTP

final class Movement: Model {
    let storage = Storage()
    
    var name: String
    var reps: Int
    var sets: Int
    var description: String?
    var image: Bool
    var restTime: Int
    
    
    struct Keys {
        static let id = "id"
        static let name = "name"
        static let reps = "reps"
        static let sets = "sets"
        static let description = "description"
        static let image = "image"
        static let restTime = "restTime"
    }
    
    init(name: String, reps: Int, sets: Int, description: String? = nil, image: Bool, restTime: Int) {
        self.name = name
        self.reps = reps
        self.sets = sets
        self.description = description
        self.image = image
        self.restTime = restTime
    }
    
    
    init(row: Row) throws {
        
        self.name = try row.get(Keys.name)
        self.reps = try row.get(Keys.reps)
        self.sets = try row.get(Keys.sets)
        self.description = try row.get(Keys.description)
        self.image = try row.get(Keys.image)
        self.restTime = try row.get(Keys.restTime)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Keys.name, name)
        try row.set(Keys.reps, reps)
        try row.set(Keys.sets, sets)
        try row.set(Keys.description, description)
        try row.set(Keys.image, image)
        try row.set(Keys.restTime, restTime)
        return row
    }
}

extension Movement: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Keys.name)
            builder.int(Keys.reps)
            builder.int(Keys.sets)
            builder.string(Keys.description)
            builder.bool(Keys.image)
            builder.int(Keys.restTime)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Movement: JSONConvertible {
    convenience init(json: JSON) throws {
        
        try self.init(
            name: json.get(Keys.name),
            reps: json.get(Keys.reps),
            sets: json.get(Keys.sets),
            description: json.get(Keys.description),
            image: json.get(Keys.image),
            restTime: json.get(Keys.restTime)
        )
        id = try json.get(Keys.id)
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Keys.id, id)
        try json.set(Keys.name, name)
        try json.set(Keys.reps, reps)
        try json.set(Keys.sets, sets)
        try json.set(Keys.description, description)
        try json.set(Keys.image, image)
        try json.set(Keys.restTime, restTime)
        return json
    }
}

extension Movement: ResponseRepresentable { }

extension Movement: Updateable {
    static var updateableKeys: [UpdateableKey<Movement>] {
        return [
            UpdateableKey(Movement.Keys.name) { movement, name in
                movement.name = name
            },
            UpdateableKey(Movement.Keys.description){ movement, desc in
                movement.description = desc
            },
            UpdateableKey(Movement.Keys.image) { movement, image in
                movement.image = image
            },
            UpdateableKey(Movement.Keys.reps) { movement, reps in
                movement.reps = reps
            },
            UpdateableKey(Movement.Keys.sets) { movement, sets in
                movement.sets = sets
            },
            UpdateableKey(Movement.Keys.restTime) { movement, restTime in
                movement.restTime = restTime
            }
        ]
    }
}

extension Movement {
    var tags: Siblings<Movement, MovementTag, Pivot<Movement, MovementTag>> {
        return siblings()
    }
}




