import Foundation
import Vapor
import AuthProvider

extension Droplet {
    func setupRoutes() throws {
        try setupTokenProtectedRoutes()
        try setupUnauthenticatedRoutes()
        try setupPasswordProtectedRoutes()
        
        let movement = MovementController()
        resource("movement", movement)
        
        let workout = WorkoutController()
        resource("workout", workout)
        
        let user = UserController()
        resource("user", user)
        
        let routine = RoutineController()
        resource("routine", routine)
        
        patch("user", String.parameter, handler: user.updateUser)
        
        get("workout", String.parameter, "movement", handler: workout.getMovements)
        get("user", String.parameter, "workout", handler: user.getUserWorkouts)
        
        get("workoutAndMovements", Int.parameter, handler: workout.getWorkoutAndMovements)
        
        get("routine", String.parameter, "day", handler: routine.getRoutineDays)
        
    }
}
