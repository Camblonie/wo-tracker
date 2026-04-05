//
//  PlannedMovement.swift
//  WO Tracker
//
//  Model for exercises within a workout plan
//

import Foundation
import SwiftData

@Model
final class PlannedMovement {
    // Unique identifier
    @Attribute(.unique) var id: UUID
    
    // Order in the workout (for sequencing)
    var orderIndex: Int
    
    // Target number of sets
    var targetSets: Int
    
    // Target number of reps per set
    var targetReps: Int
    
    // Target weight (optional - can be adjusted during workout)
    var targetWeight: Double?
    
    // Rest time in seconds between sets
    var restSeconds: Int?
    
    // Relationship to the exercise
    var exercise: Exercise?
    
    // Relationship to the workout plan
    var workoutPlan: WorkoutPlan?
    
    // Relationship to completed movements (instances of this plan item)
    @Relationship(deleteRule: .cascade, inverse: \CompletedMovement.plannedMovement)
    var completedInstances: [CompletedMovement]?
    
    init(
        id: UUID = UUID(),
        orderIndex: Int,
        targetSets: Int,
        targetReps: Int,
        targetWeight: Double? = nil,
        restSeconds: Int? = nil,
        exercise: Exercise? = nil,
        workoutPlan: WorkoutPlan? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restSeconds = restSeconds
        self.exercise = exercise
        self.workoutPlan = workoutPlan
    }
}
