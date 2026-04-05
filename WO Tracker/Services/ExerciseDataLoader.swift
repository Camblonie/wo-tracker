//
//  ExerciseDataLoader.swift
//  WO Tracker
//
//  Service to load pre-defined exercises from bundled JSON
//

import Foundation
import SwiftData

struct ExerciseDTO: Codable {
    let id: String
    let name: String
    let category: String
    let muscleGroups: [String]
    let instructions: String?
}

struct ExercisesContainer: Codable {
    let exercises: [ExerciseDTO]
}

class ExerciseDataLoader {
    
    /// Loads pre-defined exercises from bundled JSON file
    /// - Returns: Array of ExerciseDTO objects
    static func loadExercisesFromBundle() -> [ExerciseDTO] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            print("Warning: exercises.json not found in bundle")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(ExercisesContainer.self, from: data)
            return container.exercises
        } catch {
            print("Error loading exercises: \(error)")
            return []
        }
    }
    
    /// Seeds the database with built-in exercises if they don't already exist
    /// - Parameter context: SwiftData model context
    static func seedBuiltInExercises(in context: ModelContext) {
        // Check if we've already seeded exercises
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.isBuiltIn == true }
        )
        
        do {
            let existingCount = try context.fetchCount(descriptor)
            
            // If we already have built-in exercises, don't re-seed
            if existingCount > 0 {
                print("Built-in exercises already seeded (count: \(existingCount))")
                return
            }
            
            // Load exercises from JSON
            let exerciseDTOs = loadExercisesFromBundle()
            
            for dto in exerciseDTOs {
                // Parse category
                guard let category = ExerciseCategory(rawValue: dto.category) else {
                    print("Unknown category: \(dto.category)")
                    continue
                }
                
                // Create exercise with pre-defined ID based on name
                let exercise = Exercise(
                    id: UUID(uuidString: dto.id) ?? UUID(),
                    name: dto.name,
                    category: category,
                    muscleGroups: dto.muscleGroups,
                    isBuiltIn: true,
                    instructions: dto.instructions,
                    createdAt: Date()
                )
                
                context.insert(exercise)
            }
            
            print("Successfully seeded \(exerciseDTOs.count) built-in exercises")
            
        } catch {
            print("Error checking existing exercises: \(error)")
        }
    }
    
    /// Creates a sample workout plan for first-time users
    /// - Parameter context: SwiftData model context
    static func createSampleWorkoutPlan(in context: ModelContext) {
        // Check if any plans exist
        let descriptor = FetchDescriptor<WorkoutPlan>()
        
        do {
            let existingCount = try context.fetchCount(descriptor)
            
            if existingCount > 0 {
                return // Don't create sample if plans already exist
            }
            
            // Get some exercises to include in the sample plan
            let exerciseDescriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate { $0.isBuiltIn == true }
            )
            let exercises = try context.fetch(exerciseDescriptor)
            
            // Find exercises for a "Push Day" sample
            let chestExercises = exercises.filter { $0.category == .chest }.prefix(3)
            let shoulderExercises = exercises.filter { $0.category == .shoulders }.prefix(2)
            let tricepExercises = exercises.filter { $0.category == .arms && $0.name.contains("Tri") }.prefix(2)
            
            guard !chestExercises.isEmpty else {
                print("Not enough exercises to create sample plan")
                return
            }
            
            // Create sample push day plan
            let samplePlan = WorkoutPlan(
                name: "Sample Push Day",
                details: "A beginner-friendly push workout focusing on chest, shoulders, and triceps.",
                estimatedDuration: 60
            )
            context.insert(samplePlan)
            
            var orderIndex = 0
            
            // Add chest exercises
            for exercise in chestExercises {
                let movement = PlannedMovement(
                    orderIndex: orderIndex,
                    targetSets: 3,
                    targetReps: 10,
                    restSeconds: 90,
                    exercise: exercise,
                    workoutPlan: samplePlan
                )
                context.insert(movement)
                orderIndex += 1
            }
            
            // Add shoulder exercises
            for exercise in shoulderExercises {
                let movement = PlannedMovement(
                    orderIndex: orderIndex,
                    targetSets: 3,
                    targetReps: 12,
                    restSeconds: 60,
                    exercise: exercise,
                    workoutPlan: samplePlan
                )
                context.insert(movement)
                orderIndex += 1
            }
            
            // Add tricep exercises
            for exercise in tricepExercises {
                let movement = PlannedMovement(
                    orderIndex: orderIndex,
                    targetSets: 3,
                    targetReps: 12,
                    restSeconds: 60,
                    exercise: exercise,
                    workoutPlan: samplePlan
                )
                context.insert(movement)
                orderIndex += 1
            }
            
            print("Created sample workout plan with \(orderIndex) exercises")
            
        } catch {
            print("Error creating sample plan: \(error)")
        }
    }
}
