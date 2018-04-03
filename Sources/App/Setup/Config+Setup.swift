import FluentProvider
import AuthProvider

extension Config {
    public func setup() throws {
        // allow fuzzy conversions for these types
        // (add your own types here)
        Node.fuzzy = [Row.self, JSON.self, Node.self]

        try setupProviders()
        try setupPreparations()
    }
    
    /// Configure providers
    private func setupProviders() throws {
        try addProvider(FluentProvider.Provider.self)
        try addProvider(AuthProvider.Provider.self)
    }
    
    /// Add all models that should have their
    /// schemas prepared before the app boots
    private func setupPreparations() throws {
        preparations.append(Movement.self)
        preparations.append(Post.self)
        preparations.append(User.self)
        preparations.append(Token.self)
        preparations.append(Workout.self)
        preparations.append(Routine.self)
        preparations.append(RoutineDay.self)
        preparations.append(Pivot<Workout, Movement>.self)
        preparations.append(Pivot<User, Workout>.self)
        preparations.append(WorkoutTag.self)
        preparations.append(MovementTag.self)
        preparations.append(Pivot<RoutineDay, WorkoutTag>.self)
//        preparations.append(Pivot<WorkoutTag, Workout>.self)
        preparations.append(Pivot<Workout, WorkoutTag>.self)
        preparations.append(Pivot<Movement, MovementTag>.self)
    }
}
