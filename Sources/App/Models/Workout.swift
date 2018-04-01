//
//  Workout.swift
//  App
//
//  Created by Ben Kovacs on 2018-03-01.
//

import Foundation
import Vapor
import FluentProvider
import HTTP

final class Workout: Model {
    let storage = Storage()
    
    var name: String
    var creator: String
    var time: Int
    var description: String?
    var image: Bool
    var rating: Int
    
    
    struct Keys {
        static let id = "id"
        static let name = "name"
        static let creator = "creator"
        static let time = "time"
        static let description = "description"
        static let image = "image"
        static let rating = "rating"
    }
    
    init(name: String, creator: String, time: Int, description: String? = nil, image: Bool, rating: Int) {
        self.name = name
        self.creator = creator
        self.time = time
        self.description = description
        self.image = image
        self.rating = rating
    }
    
    
    init(row: Row) throws {
        self.name = try row.get(Keys.name)
        self.creator = try row.get(Keys.creator)
        self.time = try row.get(Keys.time)
        self.description = try row.get(Keys.description)
        self.image = try row.get(Keys.image)
        self.rating = try row.get(Keys.rating)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Keys.name, name)
        try row.set(Keys.creator, creator)
        try row.set(Keys.time, time)
        try row.set(Keys.description, description)
        try row.set(Keys.image, image)
        try row.set(Keys.rating, rating)
        return row
    }
}

extension Workout: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Keys.name)
            builder.string(Keys.creator)
            builder.int(Keys.time)
            builder.string(Keys.description)
            builder.bool(Keys.image)
            builder.int(Keys.rating)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Workout: JSONConvertible {
    convenience init(json: JSON) throws {
        
        try self.init(
            name: json.get(Keys.name),
            creator: json.get(Keys.creator),
            time: json.get(Keys.time),
            description: json.get(Keys.description),
            image: json.get(Keys.image),
            rating: json.get(Keys.rating)
        )
        id = try json.get(Keys.id)
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Keys.id, id)
        try json.set(Keys.name, name)
        try json.set(Keys.creator, creator)
        try json.set(Keys.time, time)
        try json.set(Keys.description, description)
        try json.set(Keys.image, image)
        try json.set(Keys.rating, rating)
        return json
    }
}

extension Workout: ResponseRepresentable { }

extension Workout: Updateable {
    static var updateableKeys: [UpdateableKey<Workout>] {
        return [
            UpdateableKey(Workout.Keys.name) { Workout, name in
                Workout.name = name
            },
            UpdateableKey(Workout.Keys.description){ Workout, desc in
                Workout.description = desc
            },
            UpdateableKey(Workout.Keys.image) { Workout, image in
                Workout.image = image
            },
            UpdateableKey(Workout.Keys.creator) { Workout, creator in
                Workout.creator = creator
            },
            UpdateableKey(Workout.Keys.time) { Workout, time in
                Workout.time = time
            },
            UpdateableKey(Workout.Keys.rating) { Workout, rating in
                Workout.rating = rating
            }
        ]
    }
}

extension Workout {
    var movements: Siblings<Workout, Movement, Pivot<Workout, Movement>> {
        return siblings()
    }
    
    var tags: Siblings<Workout, WorkoutTag, Pivot<Workout, WorkoutTag>> {
        return siblings()
    }
    
    var stringTags:[String] {
        guard let tags = try? self.tags.all() else { return [] }
        var sTags: [String] = []
        tags.forEach { sTags.append($0.name) }
        return sTags
    }
}

extension Workout {
    static func workoutAndMove(forID id: String) throws -> JSON {
        guard let workout = try Workout.find(id) else { throw Abort.badRequest }
        var stringTags: [String] = []
        let movements = try workout.movements.all()
        let tags = try workout.tags.all()
        tags.forEach { stringTags.append($0.name) }
        var jWorkout = try workout.makeJSON()
        let jMovements = try movements.makeJSON()
        try jWorkout.set("movements", jMovements)
        try jWorkout.set("tags", stringTags)
        guard let user = try User.find(workout.creator) else { throw Abort.notFound }
        let userName = user.firstname + " " + user.lastname
        try jWorkout.set("creatorName", userName)
        
        return jWorkout
    }
}

