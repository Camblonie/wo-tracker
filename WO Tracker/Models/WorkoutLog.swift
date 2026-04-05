//
//  WorkoutLog.swift
//  WO Tracker
//
//  Model for tracking exercise performance history
//

import Foundation
import SwiftData

@Model
final class WorkoutLog {
    // Unique identifier
    @Attribute(.unique) var id: UUID
    
    // Reference to the exercise
    var exercise: Exercise?
    
    // Date of the workout
    var date: Date
    
    // Weight used (in pounds or kg - user preference)
    var weight: Double
    
    // Number of reps performed
    var reps: Int
    
    // Number of sets performed
    var sets: Int
    
    // Optional notes
    var notes: String?
    
    // Reference to session ID for tracking (optional, not a bidirectional relationship)
    var sessionID: UUID?
    
    init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        date: Date = Date(),
        weight: Double = 0,
        reps: Int = 0,
        sets: Int = 0,
        notes: String? = nil,
        sessionID: UUID? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.date = date
        self.weight = weight
        self.reps = reps
        self.sets = sets
        self.notes = notes
        self.sessionID = sessionID
    }
}
