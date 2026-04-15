//
//  WorkoutHistoryService.swift
//  WO Tracker
//
//  Service for querying historical workout data
//

import Foundation
import SwiftData

/// Service for retrieving historical workout performance data
struct WorkoutHistoryService {
    let modelContext: ModelContext
    
    /// Represents a single set from a previous workout
    struct HistoricalSet {
        let reps: Int
        let weight: Double
        let setNumber: Int
    }
    
    /// Represents the last performance of an exercise
    struct LastPerformance {
        let sets: [HistoricalSet]
        let date: Date?
        let sessionID: UUID?
    }
    
    /// Get the most recent performance for a specific exercise
    /// - Parameter exercise: The exercise to look up
    /// - Returns: LastPerformance containing sets data, or nil if no history exists
    func getLastPerformance(for exercise: Exercise?) -> LastPerformance? {
        guard let exercise = exercise else { return nil }
        
        // Fetch all logs and filter in memory (SwiftData predicate can't handle optional relationships)
        let descriptor = FetchDescriptor<WorkoutLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allLogs = try modelContext.fetch(descriptor)
            let logs = allLogs.filter { $0.exercise?.id == exercise.id }
            
            // Group logs by session to reconstruct sets
            let groupedBySession = Dictionary(grouping: logs) { $0.sessionID }
            
            // Find the most recent session
            guard let mostRecentSessionID = groupedBySession.keys.compactMap({ $0 }).first,
                  let sessionLogs = groupedBySession[mostRecentSessionID] else {
                return nil
            }
            
            // Sort by sets (if available) or just use the order
            let sortedLogs = sessionLogs.sorted { $0.sets < $1.sets }
            
            // Convert to HistoricalSet
            let historicalSets = sortedLogs.enumerated().map { index, log in
                HistoricalSet(
                    reps: log.reps,
                    weight: log.weight,
                    setNumber: index + 1
                )
            }
            
            return LastPerformance(
                sets: historicalSets,
                date: sessionLogs.first?.date,
                sessionID: mostRecentSessionID
            )
            
        } catch {
            print("Failed to fetch workout history: \(error)")
            return nil
        }
    }
    
    /// Create ExerciseSetInput array from historical performance or plan defaults
    /// - Parameters:
    ///   - targetSets: Number of sets planned
    ///   - targetReps: Default reps from plan
    ///   - targetWeight: Default weight from plan
    ///   - exercise: The exercise to look up history for
    /// - Returns: Array of ExerciseSetInput populated from history or defaults
    func createSetsFromHistory(
        targetSets: Int,
        targetReps: Int,
        targetWeight: Double?,
        for exercise: Exercise?
    ) -> [ExerciseSetInput] {
        let performance = getLastPerformance(for: exercise)
        
        guard let historicalSets = performance?.sets, !historicalSets.isEmpty else {
            // No history - use plan defaults
            return (1...targetSets).map { setNumber in
                ExerciseSetInput(
                    setNumber: setNumber,
                    reps: targetReps,
                    weight: targetWeight ?? 0
                )
            }
        }
        
        // Build sets array using historical data
        var sets: [ExerciseSetInput] = []
        let historicalCount = historicalSets.count
        
        for setNumber in 1...targetSets {
            let historicalSet: HistoricalSet
            
            if setNumber <= historicalCount {
                // Use the matching historical set
                historicalSet = historicalSets[setNumber - 1]
            } else {
                // Repeat the last historical set for additional sets
                historicalSet = historicalSets[historicalCount - 1]
            }
            
            sets.append(ExerciseSetInput(
                setNumber: setNumber,
                reps: historicalSet.reps,
                weight: historicalSet.weight
            ))
        }
        
        return sets
    }
}
