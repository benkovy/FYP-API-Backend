//
//  UserController.swift
//  App
//
//  Created by Ben Kovacs on 2018-03-02.
//

import Vapor
import HTTP
import Foundation

final class UserController: ResourceRepresentable {
    
    func getUserWorkouts(_ req: Request) throws -> ResponseRepresentable {
        let id = try req.parameters.next(String.self)
        guard let user = try User.find(id) else { throw Abort.notFound }
        guard let workouts = try? user.workouts.all() else { throw Abort.notFound }
        var fullWorkouts = [JSON]()
        for workout in workouts {
            let movements = try workout.movements.all()
            var workoutJSON = try workout.makeJSON()
            let movementJSON = try movements.makeJSON()
            try workoutJSON.set("movements", movementJSON)
            fullWorkouts.append(workoutJSON)
        }
        return try fullWorkouts.makeJSON()
    }
    
    /// When users call 'GET' on '/user'
    /// it should return an index of all available user
    func index(_ req: Request) throws -> ResponseRepresentable {
        return try User.all().makeJSON()
    }
    
    /// When consumers call 'user' on '/user' with valid JSON
    /// construct and save the user
    func store(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.user()
        try user.save()
        var json = try user.makeJSON()
        if let id = user.id?.string {
            try json.set("image", UserController.image(id: id))
        }
        return json
    }
    
    /// When the consumer calls 'GET' on a specific resource, ie:
    /// '/user/13rd88' we should show that specific user
    func show(_ req: Request, user: User) throws -> ResponseRepresentable {
        return user
    }
    
    /// When the consumer calls 'DELETE' on a specific resource, ie:
    /// 'user/l2jd9' we should remove that resource from the database
    func delete(_ req: Request, user: User) throws -> ResponseRepresentable {
        try user.delete()
        return Response(status: .ok)
    }
    
    /// When the consumer calls 'DELETE' on the entire table, ie:
    /// '/user' we should remove the entire table
    func clear(_ req: Request) throws -> ResponseRepresentable {
        try User.makeQuery().delete()
        return Response(status: .ok)
    }
    
    /// When the user calls 'PATCH' on a specific resource, we should
    /// update that resource to the new values.
//    func update(_ req: Request, user: User) throws -> ResponseRepresentable {
//        // See `extension user: Updateable`
//
//        try user.update(for: req)
//
//        // Save an return the updated user.
//        try user.save()
//        var json = try user.makeJSON()
//        if let id = user.id?.string {
//            try json.set("image", UserController.image(id: id))
//        }
//        return json
//    }
    
    func updateUser(req: Request) throws -> ResponseRepresentable {
        let id = try req.parameters.next(String.self)
        
        guard let user = try User.find(id) else {throw Abort.badRequest}
        try user.update(for: req)
        var json = try user.makeJSON()
        try json.set("image", UserController.image(id: id))
        return json
        
    }
    
    /// When a user calls 'PUT' on a specific resource, we should replace any
    /// values that do not exist in the request with null.
    /// This is equivalent to creating a new user with the same ID.
    func replace(_ req: Request, user: User) throws -> ResponseRepresentable {
        // First attempt to create a new user from the supplied JSON.
        // If any required fields are missing, this request will be denied.
        let new = try req.user()
        
        // Update the user with all of the properties from
        // the new user
        user.firstname = new.firstname
        user.description = new.description
        user.lastname = new.lastname
        user.email = new.email
        user.description = new.description
        user.dateOfBirth = new.dateOfBirth
        user.type = new.type
        try user.save()
        
        // Return the updated user
        return user
    }
    
    /// When making a controller, it is pretty flexible in that it
    /// only expects closures, this is useful for advanced scenarios, but
    /// most of the time, it should look almost identical to this
    /// implementation
    func makeResource() -> Resource<User> {
        return Resource(
            index: index,
            store: store,
            show: show,
            replace: replace,
            destroy: delete,
            clear: clear
        )
    }
}

extension UserController: EmptyInitializable { }

extension UserController {
    static func image(id: String) -> String?  {
        let base = URL(fileURLWithPath: "/Users/benkovacs/Documents/workspaces/FourthYearProject/Vapor/FYP-API/").appendingPathComponent("profileImages")
        let workoutDir = base.appendingPathComponent(id)
        let workoutDirWithImage = workoutDir.appendingPathComponent("profileImage")
        return try? Data(contentsOf: workoutDirWithImage).base64EncodedString()
    }
}

