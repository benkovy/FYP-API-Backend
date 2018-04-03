//
//  MainAuthRoutes.swift
//  App
//
//  Created by Ben Kovacs on 2018-03-01.
//

import Foundation
import Vapor
import AuthProvider

extension Droplet {
    
    func setupUnauthenticatedRoutes() throws {
        
        post("profileImage") { req in
            guard
                let image = req.formData?["image"]?.bytes,
                let imageName = req.formData?["image"]?.filename
                else {
                    print("Something Went wrong")
                    throw Abort.badRequest
            }
            
            let parts = imageName.split(separator: "|")
            let id = parts[1].description
            let filename = parts[0].description
            
            let baseDir = URL(fileURLWithPath: "/Users/benkovacs/Documents/workspaces/FourthYearProject/Vapor/FYP-API/").appendingPathComponent("profileImages")
            
            let userDir = baseDir.appendingPathComponent(id)
            let fileManager = FileManager()
            
            /// check whether directory already exists
            if !fileManager.fileExists(atPath: userDir.path) {
                try fileManager.createDirectory(at: userDir, withIntermediateDirectories: false, attributes: nil)
            }
            let userDirWithImage = userDir.appendingPathComponent(filename)
            /// write image to directory
            let data = Data(bytes: image)
            fileManager.createFile(atPath: userDirWithImage.path, contents: data, attributes: nil)
            return Data(bytes: image)
        }
        
        post("image") { req in
            guard
                let image = req.formData?["image"]?.bytes,
                let imageName = req.formData?["image"]?.filename
            else {
                print("Something Went wrong")
                return "Uh oh"
            }
            
            let parts = imageName.split(separator: "|")
            let id = parts[1].description
            let filename = parts[0].description
            
            let baseDir = URL(fileURLWithPath: "/Users/benkovacs/Documents/workspaces/FourthYearProject/Vapor/FYP-API/").appendingPathComponent("images")
            
            let workoutDir = baseDir.appendingPathComponent(id)
            let fileManager = FileManager()
            
            /// check whether directory already exists
            if !fileManager.fileExists(atPath: workoutDir.path) {
                try fileManager.createDirectory(at: workoutDir, withIntermediateDirectories: false, attributes: nil)
            }
            let workoutDirWithImage = workoutDir.appendingPathComponent(filename)
            /// write image to directory
            let data = Data(bytes: image)
            fileManager.createFile(atPath: workoutDirWithImage.path, contents: data, attributes: nil)
            return Data(bytes: image)
        }
        
        // End point to check if email has been used
        post("email") { req in
            
            guard let json = req.json else {
                throw Abort(.badRequest)
            }
            
            let email = try Email(json: json)
            var response = JSON()
            try response.set("outcome", true)
            
            // ensure no user with this email already exists
            guard try User.makeQuery().filter("email", email.email).first() == nil else {
                try response.set("outcome", false)
                return response
            }
            return response
        }
        
        // create a new user
        //
        // POST /users
        // <json new user information>
        post("users") { req in
            // require that the request body be json
            guard let json = req.json else {
                throw Abort(.badRequest)
            }
            
            // initialize the name and email from
            // the request json
            let user = try User(json: json)
            
            
            
            // ensure no user with this email already exists
            guard try User.makeQuery().filter("email", user.email).first() == nil else {
                throw Abort(.badRequest, reason: "A user with that email already exists.")
            }
            
            // require a plaintext password is supplied
            guard let password = json["password"]?.string else {
                throw Abort(.badRequest)
            }
            
            // hash the password and set it on the user
            user.password = try self.hash.make(password.makeBytes()).makeString()
            
            // save and return the new user
            try user.save()
            
            return user
        }
    }
    
    /// Sets up all routes that can be accessed using
    /// username + password authentication.
    /// Since we want to minimize how often the username + password
    /// is sent, we will only use this form of authentication to
    /// log the user in.
    /// After the user is logged in, they will receive a token that
    /// they can use for further authentication.
    func setupPasswordProtectedRoutes() throws {
        // creates a route group protected by the password middleware.
        // the User type can be passed to this middleware since it
        // conforms to PasswordAuthenticatable
        let password = grouped([
            PasswordAuthenticationMiddleware(User.self)
            ])
        
        // verifies the user has been authenticated using the password
        // middleware, then generates, saves, and returns a new access token.
        //
        // POST /login
        // Authorization: Basic <base64 email:password>
        password.post("login") { req in
            let user = try req.user()
            let token = try Token.generate(for: user)
            try token.save()
            return token
        }
        
        password.post("loginForUser") { req in
            let user = try req.user()
            let token = try Token.generate(for: user)
            try token.save()
            var json = try user.makeJSON()
            try json.set("token", ["token": token.token])
            if let id = user.id?.string {
                try json.set("image", UserController.image(id: id))
            }
            return json
        }
        
        
    }
    
    /// Sets up all routes that can be accessed using
    /// the authentication token received during login.
    /// All of our secure routes will go here.
    func setupTokenProtectedRoutes() throws {
        // creates a route group protected by the token middleware.
        // the User type can be passed to this middleware since it
        // conforms to TokenAuthenticatable
        let token = grouped([
            TokenAuthenticationMiddleware(User.self)
            ])
        
        // simply returns a greeting to the user that has been authed
        // using the token middleware.
        //
        // GET /me
        // Authorization: Bearer <token from /login>
        token.get("tokenUser") { req in
            let user = try req.user()
            var json = try user.makeJSON()
            if let id = user.id?.string {
                try json.set("image", UserController.image(id: id))
            }
            return json
        }
        
        
        token.get("routineForToken") { req in
            let user = try req.user()
            guard let routine = try user.routine.first() else { throw Abort.notFound }
            var routineJson = try routine.makeJSON()
            let days = try routine.days.all()
            var newDays: [JSON] = []
            try days.forEach { day in
                if let id = day.workoutId {
                    let webworkout = try Workout.workoutAndMove(forID: id)
                    let tags = try day.tags.all()
                    let newtags = tags.compactMap { $0.name }
                    var jDay = try day.makeJSON()
                    jDay.removeKey("initialized")
                    try jDay.set("initialized", newtags)
                    try jDay.set("finalized", try [webworkout].makeJSON())
                    newDays.append(jDay)
                } else if day.initialized != nil {
                    let tags = try day.tags.all()
                    let newtags = tags.compactMap { $0.name }
                    var jDay = try day.makeJSON()
                    jDay.removeKey("initialized")
                    try jDay.set("initialized", newtags)
                    try jDay.set("finalized", try Workout.workoutAndMove(forAmount: 10, forTypes: tags))
                    newDays.append(jDay)
                } else {
                    newDays.append(try day.makeJSON())
                }
            }
            try routineJson.set("days", try newDays.makeJSON())
            return routineJson
        }
    }
}
