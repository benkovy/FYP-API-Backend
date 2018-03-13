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
        
        get("workout", String.parameter, "movement", handler: workout.getMovements)
        get("user", String.parameter, "workout", handler: user.getUserWorkouts)
        
    }
}
