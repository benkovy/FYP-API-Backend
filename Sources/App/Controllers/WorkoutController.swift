//
//  WorkoutController.swift
//  App
//
//  Created by Ben Kovacs on 2018-03-01.
//

import Vapor
import FluentProvider
import HTTP

final class WorkoutController: ResourceRepresentable {
    
    /// When users call 'GET' on '/workout/123/movements/'
    /// Look for all movements for given workout id
    func getMovements(_ req: Request) throws -> ResponseRepresentable {
        let id = try req.parameters.next(String.self)
        guard let workout = try? Workout.find(id), let movements = try? workout?.movements.all(), let json = try movements?.makeJSON() else { throw Abort.badRequest }
        return json
    }
    
    func getWorkoutAndMovements(_ req: Request) throws -> ResponseRepresentable {
//        let amount = try req.parameters.next(Int.self)
        guard let workouts = try? Workout.all() else { throw Abort.badRequest }
        var jsonWebWorkouts: [JSON] = []
        
        try workouts.forEach {
            var stringTags: [String] = []
            let movements = try $0.movements.all()
            let tags = try $0.tags.all()
            tags.forEach { stringTags.append($0.name) }
            var jWorkout = try $0.makeJSON()
            let jMovements = try movements.makeJSON()
            try jWorkout.set("movements", jMovements)
            try jWorkout.set("tags", stringTags)
            guard let user = try User.find($0.creator) else { throw Abort.notFound }
            let userName = user.firstname + " " + user.lastname
            try jWorkout.set("creatorName", userName)
            jsonWebWorkouts.append(jWorkout)
        }
        return try jsonWebWorkouts.makeJSON()
    }
    
    /// When users call 'GET' on '/workout'
    /// it should return an index of all available workout
    func index(_ req: Request) throws -> ResponseRepresentable {
        let workouts = try Workout.all()
        var jsonWorkouts: [JSON] = []
        try workouts.forEach { workout in
            guard let user = try User.find(workout.creator) else { throw Abort.notFound }
            let userName = user.firstname + " " + user.lastname
            var json = try workout.makeJSON()
            try json.set("creatorName", userName)
            jsonWorkouts.append(json)
        }
        return try jsonWorkouts.makeJSON()
    }
    
    /// When consumers call 'workout' on '/workout' with valid JSON
    /// construct and save the workout
    func store(_ req: Request) throws -> ResponseRepresentable {
        let workout = try req.workout()
        guard let user = try User.find(workout.creator) else { throw Abort.notFound }
        let userName = user.firstname + " " + user.lastname
        var json = try workout.makeJSON()
        try json.set("creatorName", userName)
        var jW = try workout.makeJSON()
        try jW.set("tags", workout.stringTags)
        return jW
    }
    
    /// When the consumer calls 'GET' on a specific resource, ie:
    /// '/workout/13rd88' we should show that specific workout
    func show(_ req: Request, workout: Workout) throws -> ResponseRepresentable {
        return workout
    }
    
    /// When the consumer calls 'DELETE' on a specific resource, ie:
    /// 'workout/l2jd9' we should remove that resource from the database
    func delete(_ req: Request, workout: Workout) throws -> ResponseRepresentable {
        try workout.delete()
        return Response(status: .ok)
    }
    
    /// When the consumer calls 'DELETE' on the entire table, ie:
    /// '/workout' we should remove the entire table
    func clear(_ req: Request) throws -> ResponseRepresentable {
        try Workout.makeQuery().delete()
        return Response(status: .ok)
    }
    
    /// When the user calls 'PATCH' on a specific resource, we should
    /// update that resource to the new values.
    func update(_ req: Request, workout: Workout) throws -> ResponseRepresentable {
        // See `extension workout: Updateable`
        try workout.update(for: req)
        
        // Save an return the updated workout.
        try workout.save()
        return workout
    }
    
    /// When a user calls 'PUT' on a specific resource, we should replace any
    /// values that do not exist in the request with null.
    /// This is equivalent to creating a new workout with the same ID.
    func replace(_ req: Request, workout: Workout) throws -> ResponseRepresentable {
        // First attempt to create a new workout from the supplied JSON.
        // If any required fields are missing, this request will be denied.
        let new = try req.workout()
        
        // Update the workout with all of the properties from
        // the new workout
        workout.name = new.name
        workout.description = new.description
        workout.image = new.image
        workout.creator = new.creator
        workout.time = new.time
        workout.rating = new.rating
        try workout.save()
        
        // Return the updated workout
        return workout
    }
    
    /// When making a controller, it is pretty flexible in that it
    /// only expects closures, this is useful for advanced scenarios, but
    /// most of the time, it should look almost identical to this
    /// implementation
    func makeResource() -> Resource<Workout> {
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
    func workout() throws -> Workout {
        guard var json = json else { throw Abort.badRequest }
        
        // 1. Save movements
        // 2. Strip movements out of workout
        // 3. Save workout
        // 4. Store workout in pivot with user
        // 5. Store movements in pivot with workout
        // 6. Save Tags in pivot with workout
        // 7. Return workout
        
        // 1.
        let movements: [Movement] = try json.get("movements")
        let _ = movements.map { try? $0.save() }
        let tags: [String] = try json.get("tags")
        var workoutTags: [WorkoutTag] = []
        try tags.forEach { tag in
            let wTag = WorkoutTag(name: tag)
            workoutTags.append(wTag)
            try wTag.save()
        }
        
        // 2.
        json.removeKey("movements")
        json.removeKey("tags")
        
        // 3.
        guard let workout = try? Workout(json: json) else { throw Abort.badRequest }
        try workout.save()
        
        // 4.
        guard let user = try User.find(workout.creator) else { throw Abort.notFound }
        let pivot = try Pivot<User, Workout>(user, workout)
        try pivot.save()
        
        // 5.
        for movement in movements {
            let pivot = try Pivot<Workout, Movement>(workout, movement)
            try pivot.save()
        }
        
        // 6.
        
        try workoutTags.forEach { tag in
            let pivot = try Pivot<Workout, WorkoutTag>(workout, tag)
            try pivot.save()
        }
        
        // 7.
        return workout
    }
}

extension WorkoutController: EmptyInitializable { }

