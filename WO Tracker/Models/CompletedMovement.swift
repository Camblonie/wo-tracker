//
//  CompletedMovement.swift
//  WO Tracker
//
//  Model for tracking a completed exercise within a workout session
//

import Foundation
import SwiftData

@Model
final class CompletedMovement {
    // Unique identifier
    @Attribute(.unique) var id: UUID
    
    // Relationship to the exercise
    var exercise: Exercise?
    
    // Relationship to the workout session
    var session: WorkoutSession?
    
    // Relationship to the planned movement (if from a plan)
    var plannedMovement: PlannedMovement?
    
    // Order in the workout (for free-form or reordered exercises)
    var orderIndex: Int
    
    // When this exercise was started
    var startedAt: Date
    
    // When this exercise was completed
    var completedAt: Date?
    
    // Notes for this specific exercise
    var notes: String?
    
    // Relationship to individual sets
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.completedMovement)
    var sets: [ExerciseSet]?
    
    // Computed property to get sorted sets
    var sortedSets: [ExerciseSet] {
        (sets ?? []).sorted { $0.setNumber < $1.setNumber }
    }
    
    // Computed property for total volume (weight × reps × sets)
    var totalVolume: Double {
        sortedSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        session: WorkoutSession? = nil,
        plannedMovement: PlannedMovement? = nil,
        orderIndex: Int = 0,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.session = session
        self.plannedMovement = plannedMovement
        self.orderIndex = orderIndex
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.notes = notes
    }
}
