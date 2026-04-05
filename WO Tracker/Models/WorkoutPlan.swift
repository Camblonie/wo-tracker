//
//  WorkoutPlan.swift
//  WO Tracker
//
//  Model for workout plan templates
//

import Foundation
import SwiftData

@Model
final class WorkoutPlan {
    // Unique identifier
    @Attribute(.unique) var id: UUID
    
    // Name of the workout plan (e.g., "Push Day", "Leg Day")
    var name: String
    
    // Optional description/details for the plan
    var details: String?
    
    // Creation date
    var createdAt: Date
    
    // Last time this plan was performed
    var lastPerformed: Date?
    
    // Estimated duration in minutes
    var estimatedDuration: Int?
    
    // Relationship to planned movements (the exercises in this plan)
    @Relationship(deleteRule: .cascade, inverse: \PlannedMovement.workoutPlan)
    var movements: [PlannedMovement]?
    
    // Relationship to workout sessions created from this plan
    @Relationship(deleteRule: .nullify, inverse: \WorkoutSession.plan)
    var sessions: [WorkoutSession]?
    
    // Computed property to get sorted movements
    var sortedMovements: [PlannedMovement] {
        (movements ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        details: String? = nil,
        createdAt: Date = Date(),
        lastPerformed: Date? = nil,
        estimatedDuration: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.createdAt = createdAt
        self.lastPerformed = lastPerformed
        self.estimatedDuration = estimatedDuration
    }
}
