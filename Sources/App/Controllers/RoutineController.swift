//
//  RoutineController.swift
//  FYP-APIPackageDescription
//
//  Created by Ben Kovacs on 2018-03-13.
//

import Vapor
import FluentProvider
import HTTP

final class RoutineController: ResourceRepresentable {
    
    func getRoutineDays(_ req: Request) throws -> ResponseRepresentable {
        let id = try req.parameters.next(String.self)
        guard let routine = try Routine.find(id) else { throw Abort.notFound }
        let days = try routine.days.all()
        return try days.makeJSON()
    }
    
    /// When users call 'GET' on '/routine'
    /// it should return an index of all available routine
    func index(_ req: Request) throws -> ResponseRepresentable {
        return try Routine.all().makeJSON()
    }
    
    /// When consumers call 'routine' on '/routine' with valid JSON
    /// construct and save the routine
    func store(_ req: Request) throws -> ResponseRepresentable {
        let routine = try req.routine()
        var routineJson = try routine.makeJSON()
        let days = try routine.days.all()
        let daysJson = try days.makeJSON()
        try routineJson.set("days", daysJson)
        return routineJson
    }
    
    /// When the consumer calls 'GET' on a specific resource, ie:
    /// '/routine/13rd88' we should show that specific routine
    func show(_ req: Request, routine: Routine) throws -> ResponseRepresentable {
        return routine
    }
    
    /// When the consumer calls 'DELETE' on a specific resource, ie:
    /// 'routine/l2jd9' we should remove that resource from the database
    func delete(_ req: Request, routine: Routine) throws -> ResponseRepresentable {
        try routine.delete()
        return Response(status: .ok)
    }
    
    /// When the consumer calls 'DELETE' on the entire table, ie:
    /// '/routine' we should remove the entire table
    func clear(_ req: Request) throws -> ResponseRepresentable {
        try Routine.makeQuery().delete()
        return Response(status: .ok)
    }
    
    /// When the user calls 'PATCH' on a specific resource, we should
    /// update that resource to the new values.
    func update(_ req: Request, routine: Routine) throws -> ResponseRepresentable {
        // See `extension routine: Updateable`
        try routine.update(for: req)
        
        // Save an return the updated routine.
        try routine.save()
        return routine
    }
    
    /// When making a controller, it is pretty flexible in that it
    /// only expects closures, this is useful for advanced scenarios, but
    /// most of the time, it should look almost identical to this
    /// implementation
    func makeResource() -> Resource<Routine> {
        return Resource(
            index: index,
            store: store,
            show: show,
            update: update,
            destroy: delete,
            clear: clear
        )
    }
}

extension Request {
    func routine() throws -> Routine {
        guard var json = json else { throw Abort.badRequest }
        // Get individual routine days
        // Remove days from routine
        let days: [RoutineDay] = try json.get("days")
        json.removeKey("days")
        
        // Try to create routine
        guard let routine = try? Routine(json: json) else { throw Abort.badRequest }
        
        // Make sure that there is a user for new routine
        guard let user = try User.find(routine.userIdKey?.string) else { throw Abort.badRequest }
        
        // Remove current routine from user
        if let currentRoutine = try user.routine.first() {
            try currentRoutine.days.delete()
            try currentRoutine.delete()
        }
        
        // Save new routine
        routine.userIdKey = user.id
        try routine.save()
        
        // Save all days to each routine
        try days.forEach {
            $0.routineIdKey = routine.id
            try $0.save()
        }
        return routine
    }
}

extension RoutineController: EmptyInitializable { }

