//
//  MovementController.swift
//  App
//
//  Created by Ben Kovacs on 2018-02-27.
//

import Vapor
import HTTP

final class MovementController: ResourceRepresentable {
    /// When users call 'GET' on '/movement'
    /// it should return an index of all available movement
    func index(_ req: Request) throws -> ResponseRepresentable {
        return try Movement.all().makeJSON()
    }
    
    /// When consumers call 'movement' on '/movement' with valid JSON
    /// construct and save the movement
    func store(_ req: Request) throws -> ResponseRepresentable {
        let movement = try req.movement()
        try movement.save()
        return movement
    }
    
    /// When the consumer calls 'GET' on a specific resource, ie:
    /// '/movement/13rd88' we should show that specific movement
    func show(_ req: Request, movement: Movement) throws -> ResponseRepresentable {
        return movement
    }
    
    /// When the consumer calls 'DELETE' on a specific resource, ie:
    /// 'movement/l2jd9' we should remove that resource from the database
    func delete(_ req: Request, movement: Movement) throws -> ResponseRepresentable {
        try movement.delete()
        return Response(status: .ok)
    }
    
    /// When the consumer calls 'DELETE' on the entire table, ie:
    /// '/movement' we should remove the entire table
    func clear(_ req: Request) throws -> ResponseRepresentable {
        try Movement.makeQuery().delete()
        return Response(status: .ok)
    }
    
    /// When the user calls 'PATCH' on a specific resource, we should
    /// update that resource to the new values.
    func update(_ req: Request, movement: Movement) throws -> ResponseRepresentable {
        // See `extension movement: Updateable`
        try movement.update(for: req)
        
        // Save an return the updated movement.
        try movement.save()
        return movement
    }
    
    /// When a user calls 'PUT' on a specific resource, we should replace any
    /// values that do not exist in the request with null.
    /// This is equivalent to creating a new movement with the same ID.
    func replace(_ req: Request, movement: Movement) throws -> ResponseRepresentable {
        // First attempt to create a new movement from the supplied JSON.
        // If any required fields are missing, this request will be denied.
        let new = try req.movement()
        
        // Update the movement with all of the properties from
        // the new movement
        movement.name = new.name
        movement.description = new.description
        movement.image = new.image
        movement.reps = new.reps
        movement.sets = new.sets
        movement.superid = new.superid
        movement.superset = new.superset
        try movement.save()
        
        // Return the updated movement
        return movement
    }
    
    /// When making a controller, it is pretty flexible in that it
    /// only expects closures, this is useful for advanced scenarios, but
    /// most of the time, it should look almost identical to this
    /// implementation
    func makeResource() -> Resource<Movement> {
        return Resource(
            index: index,
            store: store,
            show: show,
            update: update,
            replace: replace,
            destroy: delete,
            clear: clear
        )
    }
}

extension Request {
    func movement() throws -> Movement {
        guard let json = json else { throw Abort.badRequest }
        return try Movement(json: json)
    }
}

extension MovementController: EmptyInitializable { }

