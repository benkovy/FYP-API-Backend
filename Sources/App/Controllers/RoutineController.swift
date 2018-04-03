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
        let days: [JSON] = try json.get("days")
        json.removeKey("days")
        // Try to create routine
        guard let routine = try? Routine(json: json) else { throw Abort.badRequest }
        // Make sure that there is a user for new routine
        guard let user = try User.find(routine.userIdKey?.string) else { throw Abort.badRequest }
        
        // Remove current routine from user
        if let currentRoutine = try user.routine.first() {
            if let days = try? currentRoutine.days.all() {
                try days.forEach { day in
                    try day.tags.all().forEach { tag in
                        try day.tags.remove(tag)
                    }
                }
            }
            try currentRoutine.days.delete()
            try currentRoutine.delete()
        }
        
        // Save new routine
        routine.userIdKey = user.id
        try routine.save()
        
        // Save all days to routine
        try days.forEach {
            let dayWrapper = try DayWrapper(json: $0)
            let dayTosave = RoutineDay(
                day: dayWrapper.day,
                empty: dayWrapper.empty,
                initialized: dayWrapper.initialized?.joined(separator: "|"),
                workoutId: dayWrapper.workoutId,
                routineIdKey: routine.id
            )
            try dayTosave.save()
            
            if let tags = dayWrapper.initialized {
                for tag in tags {
                    if let wasTag = try WorkoutTag.makeQuery().filter("name", .equals, tag).first() {
                        let pivot = try Pivot<RoutineDay, WorkoutTag>(dayTosave, wasTag)
                        try pivot.save()
                    } else {
                        let t = WorkoutTag(name: tag)
                        try t.save()
                        let pivot = try Pivot<RoutineDay, WorkoutTag>(dayTosave, t)
                        try pivot.save()
                    }
                }
            }
        }
        return routine
    }
}

extension RoutineController: EmptyInitializable { }

