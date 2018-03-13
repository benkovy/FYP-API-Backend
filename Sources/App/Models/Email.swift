//
//  Email.swift
//  FYP-APIPackageDescription
//
//  Created by Ben Kovacs on 2018-01-26.
//

import Foundation
import Vapor

struct Email {
    let email: String
}

extension Email: JSONConvertible {
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("email", email)
        return json
    }
    
    init(json: JSON) throws {
        try self.init(
            email: json.get("email")
        )
    }
}
