//
//  PlanDetailView.swift
//  WO Tracker
//
//  View for displaying a specific workout plan with its exercises
//

import SwiftUI
import SwiftData

struct PlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let plan: WorkoutPlan
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var isReordering = false
    @State private var orderedMovements: [PlannedMovement] = []
    @State private var showingActiveWorkout = false
    
    // MARK: - View Sections
    
    @ViewBuilder
    private var reorderingSection: some View {
        if isReordering {
            Section {
                Button {
                    saveReorderedMovements()
                    isReordering = false
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Done Reordering")
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(plan.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if let duration = plan.estimatedDuration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text("\(duration) min")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                if let details = plan.details, !details.isEmpty {
                    Text(details)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if let lastPerformed = plan.lastPerformed {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Last performed: \(lastPerformed, format: .dateTime.month().day().year())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private var exercisesSection: some View {
        if isReordering {
            Section("Exercises (\(orderedMovements.count))") {
                ForEach(Array(orderedMovements.enumerated()), id: \.element.id) { index, movement in
                    PlannedMovementRow(index: index + 1, movement: movement, isReordering: true)
                }
                .onMove(perform: moveMovement)
            }
        } else {
            Section("Exercises (\(plan.sortedMovements.count))") {
                if plan.sortedMovements.isEmpty {
                    Text("No exercises added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(Array(plan.sortedMovements.enumerated()), id: \.element.id) { index, movement in
                        PlannedMovementRow(index: index + 1, movement: movement, isReordering: false)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var actionsSection: some View {
        Section {
            Button {
                showingActiveWorkout = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Workout")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.blue)
            
            Button {
                showingEditSheet = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Plan")
                }
            }
            
            Button {
                if !isReordering {
                    orderedMovements = plan.sortedMovements
                }
                isReordering.toggle()
            } label: {
                HStack {
                    Image(systemName: isReordering ? "xmark.circle" : "arrow.up.arrow.down")
                    Text(isReordering ? "Cancel Reorder" : "Reorder Exercises")
                }
                .foregroundColor(isReordering ? .orange : .blue)
            }
            
            Button {
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Plan")
                }
                .foregroundColor(.red)
            }
        }
    }
    
    var body: some View {
        List {
            reorderingSection
            headerSection
            exercisesSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Plan Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            PlanEditorView(plan: plan)
        }
        .sheet(isPresented: $showingActiveWorkout) {
            ActiveWorkoutView(plan: plan)
        }
        .alert("Delete Workout Plan?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePlan()
            }
        } message: {
            Text("This will permanently delete '\(plan.name)' and all associated data.")
        }
    }
    
    private func deletePlan() {
        modelContext.delete(plan)
        dismiss()
    }
    
    private func moveMovement(from source: IndexSet, to destination: Int) {
        orderedMovements.move(fromOffsets: source, toOffset: destination)
    }
    
    private func saveReorderedMovements() {
        // Update orderIndex for all movements
        for (index, movement) in orderedMovements.enumerated() {
            movement.orderIndex = index
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save reordered movements: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct PlannedMovementRow: View {
    let index: Int
    let movement: PlannedMovement
    var isReordering: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Order number or drag handle
            if isReordering {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            } else {
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(categoryColor)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let exercise = movement.exercise {
                    Text(exercise.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        Text("\(movement.targetSets) sets")
                        Text("×")
                        Text("\(movement.targetReps) reps")
                        
                        if let weight = movement.targetWeight, weight > 0 {
                            Text("@")
                            Text("\(String(format: "%.1f", weight)) lbs")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } else {
                    Text("Unknown Exercise")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let rest = movement.restSeconds, rest > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "timer")
                        .font(.caption)
                    Text("\(rest)s")
                        .font(.caption)
                }
                .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
    
    var categoryColor: Color {
        guard let exercise = movement.exercise else { return .gray }
        switch exercise.category {
        case .chest: return .red
        case .back: return .blue
        case .legs: return .green
        case .shoulders: return .orange
        case .arms: return .purple
        case .core: return .yellow
        case .cardio: return .pink
        }
    }
}

#Preview {
    NavigationStack {
        PlanDetailView(plan: WorkoutPlan(
            name: "Push Day",
            details: "Chest, shoulders, and triceps focus",
            estimatedDuration: 60
        ))
    }
    .modelContainer(for: WorkoutPlan.self, inMemory: true)
}
