//
//  WO_TrackerApp.swift
//  WO Tracker
//
//  Created by Scott Campbell on 4/4/26.
//

import SwiftUI
import SwiftData

@main
struct WO_TrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            WorkoutPlan.self,
            PlannedMovement.self,
            WorkoutSession.self,
            CompletedMovement.self,
            ExerciseSet.self,
            WorkoutLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Seed pre-defined exercises on first launch
            let context = ModelContext(container)
            ExerciseDataLoader.seedBuiltInExercises(in: context)
            ExerciseDataLoader.createSampleWorkoutPlan(in: context)
            try context.save()
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
