//
//  ExerciseSet.swift
//  WO Tracker
//
//  Model for tracking individual sets of an exercise
//

import Foundation
import SwiftData

@Model
final class ExerciseSet {
    // Unique identifier
    @Attribute(.unique) var id: UUID
    
    // Set number (1st set, 2nd set, etc.)
    var setNumber: Int
    
    // Number of reps performed
    var reps: Int
    
    // Weight used
    var weight: Double
    
    // Whether this set was completed
    var isCompleted: Bool
    
    // Whether this set was skipped
    var isSkipped: Bool
    
    // Whether this was a warm-up set
    var isWarmup: Bool
    
    // Whether this set was to failure
    var isToFailure: Bool
    
    // Perceived exertion (RPE 1-10)
    var rpe: Int?
    
    // Optional notes for this specific set
    var notes: String?
    
    // When this set was completed
    var completedAt: Date?
    
    // Rest time taken before this set (in seconds)
    var restSeconds: Int?
    
    // Relationship to the completed movement
    var completedMovement: CompletedMovement?
    
    // Computed volume for this set (weight × reps)
    var volume: Double {
        weight * Double(reps)
    }
    
    init(
        id: UUID = UUID(),
        setNumber: Int,
        reps: Int = 0,
        weight: Double = 0,
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        isWarmup: Bool = false,
        isToFailure: Bool = false,
        rpe: Int? = nil,
        notes: String? = nil,
        completedAt: Date? = nil,
        restSeconds: Int? = nil,
        completedMovement: CompletedMovement? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
        self.isWarmup = isWarmup
        self.isToFailure = isToFailure
        self.rpe = rpe
        self.notes = notes
        self.completedAt = completedAt
        self.restSeconds = restSeconds
        self.completedMovement = completedMovement
    }
}
