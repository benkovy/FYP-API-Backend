//
//  User.swift
//  FYP-APIPackageDescription
//
//  Created by Ben Kovacs on 2018-01-24.
//

import Foundation
import Vapor
import FluentProvider
import AuthProvider
import HTTP

final class User: Model {
    let storage = Storage()
    
    var firstname: String
    var lastname: String
    var email: String
    var password: String?
    var description: String
    var dateOfBirth: Date
    var type: String
    
    
    struct Keys {
        static let id = "id"
        static let firstname = "firstname"
        static let lastname = "lastname"
        static let email = "email"
        static let password = "password"
        static let description = "description"
        static let dateOfBirth = "dateofbirth"
        static let type = "type"
    }
    
    init(firstname: String, lastname: String, email: String, password: String? = nil, description: String, dateOfBirth: Date, type: String) {
        self.firstname = firstname
        self.lastname = lastname
        self.email = email
        self.password = password
        self.description = description
        self.dateOfBirth = dateOfBirth
        self.type = type
    }
    
    
    init(row: Row) throws {
        self.firstname = try row.get(Keys.firstname)
        self.lastname = try row.get(Keys.lastname)
        self.email = try row.get(Keys.email)
        self.password = try row.get(Keys.password)
        self.description = try row.get(Keys.description)
        self.dateOfBirth = try row.get(Keys.dateOfBirth)
        self.type = try row.get(Keys.type)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Keys.firstname, firstname)
        try row.set(Keys.lastname, lastname)
        try row.set(Keys.email, email)
        try row.set(Keys.password, password)
        try row.set(Keys.description, description)
        try row.set(Keys.dateOfBirth, dateOfBirth)
        try row.set(Keys.type, type)
        return row
    }
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Keys.firstname)
            builder.string(Keys.lastname)
            builder.string(Keys.email)
            builder.string(Keys.password)
            builder.string(Keys.description)
            builder.date(Keys.dateOfBirth)
            builder.string(Keys.type)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension User: JSONConvertible {
    convenience init(json: JSON) throws {
        
        let dateString: String = try json.get(Keys.dateOfBirth)
        guard let date = dateString.stringToDate(withFormat: "MMM d, yyyy") else { throw "Cannot make date" }
        
        try self.init(
            firstname: json.get(Keys.firstname),
            lastname: json.get(Keys.lastname),
            email: json.get(Keys.email),
            description: json.get(Keys.description),
            dateOfBirth: date,
            type: json.get(Keys.type)
        )
        id = try json.get(Keys.id)
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Keys.id, id)
        try json.set(Keys.firstname, firstname)
        try json.set(Keys.lastname, lastname)
        try json.set(Keys.email, email)
        try json.set(Keys.description, description)
        try json.set(Keys.dateOfBirth, dateOfBirth)
        try json.set(Keys.type, type)
        return json
    }
}

extension User: ResponseRepresentable { }

extension User: Updateable {
    static var updateableKeys: [UpdateableKey<User>] {
        return [
            UpdateableKey(User.Keys.firstname) { user, firstname in
                user.firstname = firstname
            },
            UpdateableKey(User.Keys.description){ user, desc in
                user.description = desc
            },
            UpdateableKey(User.Keys.lastname) { user, lastname in
                user.lastname = lastname
            },
            UpdateableKey(User.Keys.email) { user, email in
                user.email = email
            },
            UpdateableKey(User.Keys.dateOfBirth) { user, dateOfBirth in
                user.dateOfBirth = dateOfBirth
            },
            UpdateableKey(User.Keys.type) { user, type in
                user.type = type
            }
        ]
    }
}

private var _userPasswordVerifier: PasswordVerifier? = nil

extension User: PasswordAuthenticatable {
    var hashedPassword: String? {
        return password
    }
    
    public static var passwordVerifier: PasswordVerifier? {
        get { return _userPasswordVerifier }
        set { _userPasswordVerifier = newValue }
    }
}

extension Request {
    func user() throws -> User {
        return try auth.assertAuthenticated()
    }
}

extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

extension User {
    var workouts: Siblings<User, Workout, Pivot<User, Workout>> {
        return siblings()
    }
}




