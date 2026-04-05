//
//  Exercise.swift
//  WO Tracker
//
//  Exercise model representing a single exercise movement
//

import Foundation
import SwiftData

// MARK: - Exercise Category Enum
enum ExerciseCategory: String, Codable, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case cardio = "Cardio"
    
    var icon: String {
        switch self {
        case .chest: return "figure.chest"
        case .back: return "figure.back"
        case .legs: return "figure.walk"
        case .shoulders: return "figure.arms.open"
        case .arms: return "figure.arms.flexed"
        case .core: return "figure.core.training"
        case .cardio: return "figure.run"
        }
    }
    
    var color: String {
        switch self {
        case .chest: return "red"
        case .back: return "blue"
        case .legs: return "green"
        case .shoulders: return "orange"
        case .arms: return "purple"
        case .core: return "yellow"
        case .cardio: return "pink"
        }
    }
}

// MARK: - Exercise Model
@Model
final class Exercise {
    // Unique identifier for the exercise
    @Attribute(.unique) var id: UUID
    
    // Display name of the exercise
    var name: String
    
    // Category for grouping and filtering
    var categoryRaw: String
    
    // Primary muscle groups targeted (stored as comma-separated string)
    var muscleGroups: String
    
    // Whether this is a built-in exercise or user-created
    var isBuiltIn: Bool
    
    // Optional description/instructions
    var instructions: String?
    
    // Creation timestamp
    var createdAt: Date
    
    // Relationship to workout logs
    @Relationship(deleteRule: .cascade, inverse: \WorkoutLog.exercise)
    var logs: [WorkoutLog]?
    
    // Relationship to planned movements
    @Relationship(deleteRule: .nullify, inverse: \PlannedMovement.exercise)
    var plannedMovements: [PlannedMovement]?
    
    // Relationship to completed movements
    @Relationship(deleteRule: .nullify, inverse: \CompletedMovement.exercise)
    var completedMovements: [CompletedMovement]?
    
    // Computed property to access category enum
    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .chest }
        set { categoryRaw = newValue.rawValue }
    }
    
    // Computed property to get muscle groups as array
    var muscleGroupsArray: [String] {
        muscleGroups.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory,
        muscleGroups: [String] = [],
        isBuiltIn: Bool = false,
        instructions: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.muscleGroups = muscleGroups.joined(separator: ", ")
        self.isBuiltIn = isBuiltIn
        self.instructions = instructions
        self.createdAt = createdAt
    }
}
