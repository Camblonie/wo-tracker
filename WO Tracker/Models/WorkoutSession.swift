//
//  WorkoutSession.swift
//  WO Tracker
//
//  Model for tracking an actual workout session
//

import Foundation
import SwiftData

enum WorkoutStatus: String, Codable {
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

@Model
final class WorkoutSession {
    // Unique identifier
    @Attribute(.unique) var id: UUID
    
    // Reference to the plan (optional - can be free-form workout)
    var plan: WorkoutPlan?
    
    // When the workout started
    var startedAt: Date
    
    // When the workout ended
    var completedAt: Date?
    
    // Current status
    var statusRaw: String
    
    // Overall notes for the workout
    var notes: String?
    
    // Overall rating (1-5 stars)
    var rating: Int?
    
    // Relationship to completed movements
    @Relationship(deleteRule: .cascade, inverse: \CompletedMovement.session)
    var completedMovements: [CompletedMovement]?
    
    // Computed property for status enum
    var status: WorkoutStatus {
        get { WorkoutStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }
    
    // Computed property for duration
    var duration: TimeInterval? {
        guard let completedAt = completedAt else { return nil }
        return completedAt.timeIntervalSince(startedAt)
    }
    
    // Computed property for duration in minutes
    var durationMinutes: Int? {
        guard let duration = duration else { return nil }
        return Int(duration / 60)
    }
    
    init(
        id: UUID = UUID(),
        plan: WorkoutPlan? = nil,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        status: WorkoutStatus = .inProgress,
        notes: String? = nil,
        rating: Int? = nil
    ) {
        self.id = id
        self.plan = plan
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.statusRaw = status.rawValue
        self.notes = notes
        self.rating = rating
    }
}
