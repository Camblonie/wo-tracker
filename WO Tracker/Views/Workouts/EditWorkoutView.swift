//
//  EditWorkoutView.swift
//  WO Tracker
//
//  View for editing completed workout sessions
//

import SwiftUI
import SwiftData

struct EditWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let session: WorkoutSession
    
    @State private var movements: [EditableMovement] = []
    @State private var workoutNotes: String = ""
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                // Workout notes section
                Section("Workout Notes") {
                    TextEditor(text: $workoutNotes)
                        .frame(minHeight: 60)
                }
                
                // Exercises section
                ForEach($movements) { $movement in
                    Section(movement.exerciseName) {
                        // Exercise notes
                        TextField("Exercise notes...", text: $movement.notes, axis: .vertical)
                            .font(.caption)
                        
                        // Sets editor
                        ForEach($movement.sets) { $set in
                            HStack(spacing: 12) {
                                Text("Set \(set.setNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .leading)
                                
                                // Reps input
                                HStack(spacing: 4) {
                                    TextField("Reps", value: $set.reps, format: .number)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 50)
                                    Text("reps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Weight input
                                HStack(spacing: 4) {
                                    TextField("Weight", value: $set.weight, format: .number)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 60)
                                    Text("lbs")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Completion toggle
                                Button {
                                    set.isCompleted.toggle()
                                } label: {
                                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(set.isCompleted ? .green : .secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Add set button
                        Button {
                            addSet(to: &movement)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add Set")
                            }
                            .foregroundColor(.blue)
                        }
                        
                        // Remove set button (if more than 1 set)
                        if movement.sets.count > 1 {
                            Button {
                                removeLastSet(from: &movement)
                            } label: {
                                HStack {
                                    Image(systemName: "minus.circle")
                                    Text("Remove Last Set")
                                }
                                .foregroundColor(.red)
                            }
                        }
                        
                        // Volume summary
                        let volume = movement.sets.filter { $0.isCompleted }.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
                        if volume > 0 {
                            HStack {
                                Spacer()
                                Text("Volume: \(Int(volume)) lbs")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        showingSaveConfirmation = true
                    }
                }
            }
            .alert("Save Changes?", isPresented: $showingSaveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Save", role: .destructive) {
                    saveChanges()
                }
            } message: {
                Text("This will update your workout history.")
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        // Load workout notes
        workoutNotes = session.notes ?? ""
        
        // Load movements and sets
        movements = (session.completedMovements ?? [])
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { movement in
                EditableMovement(
                    id: movement.id,
                    exerciseName: movement.exercise?.name ?? "Unknown Exercise",
                    originalMovement: movement,
                    notes: movement.notes ?? "",
                    sets: (movement.sets ?? [])
                        .sorted { $0.setNumber < $1.setNumber }
                        .map { set in
                            EditableSet(
                                id: set.id,
                                setNumber: set.setNumber,
                                reps: set.reps,
                                weight: set.weight,
                                isCompleted: set.isCompleted,
                                originalSet: set
                            )
                        }
                )
            }
    }
    
    private func addSet(to movement: inout EditableMovement) {
        let newSetNumber = movement.sets.count + 1
        let lastSet = movement.sets.last
        let newSet = EditableSet(
            id: UUID(),
            setNumber: newSetNumber,
            reps: lastSet?.reps ?? 10,
            weight: lastSet?.weight ?? 0,
            isCompleted: false,
            originalSet: nil
        )
        movement.sets.append(newSet)
    }
    
    private func removeLastSet(from movement: inout EditableMovement) {
        guard movement.sets.count > 1 else { return }
        movement.sets.removeLast()
    }
    
    private func saveChanges() {
        // Update workout notes
        session.notes = workoutNotes.isEmpty ? nil : workoutNotes
        
        // Update each movement and its sets
        for editableMovement in movements {
            guard let originalMovement = editableMovement.originalMovement else { continue }
            
            // Update exercise notes
            originalMovement.notes = editableMovement.notes.isEmpty ? nil : editableMovement.notes
            
            // Update existing sets and create new ones
            for editableSet in editableMovement.sets {
                if let originalSet = editableSet.originalSet {
                    // Update existing set
                    originalSet.reps = editableSet.reps
                    originalSet.weight = editableSet.weight
                    originalSet.isCompleted = editableSet.isCompleted
                } else {
                    // Create new set
                    let newSet = ExerciseSet(
                        id: editableSet.id,
                        setNumber: editableSet.setNumber,
                        reps: editableSet.reps,
                        weight: editableSet.weight,
                        isCompleted: editableSet.isCompleted,
                        completedMovement: originalMovement
                    )
                    modelContext.insert(newSet)
                }
            }
            
            // Remove sets that were deleted (if any) - sets with higher numbers than current
            let currentSetNumbers = Set(editableMovement.sets.map { $0.setNumber })
            if let existingSets = originalMovement.sets {
                for existingSet in existingSets {
                    if !currentSetNumbers.contains(existingSet.setNumber) {
                        modelContext.delete(existingSet)
                    }
                }
            }
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save workout changes: \(error)")
        }
        
        dismiss()
    }
}

// MARK: - Editable Data Structures

struct EditableMovement: Identifiable {
    let id: UUID
    let exerciseName: String
    let originalMovement: CompletedMovement?
    var notes: String
    var sets: [EditableSet]
}

struct EditableSet: Identifiable {
    let id: UUID
    var setNumber: Int
    var reps: Int
    var weight: Double
    var isCompleted: Bool
    let originalSet: ExerciseSet?
}

#Preview {
    NavigationStack {
        EditWorkoutView(session: WorkoutSession(
            plan: nil,
            startedAt: Date(),
            completedAt: Date(),
            status: .completed,
            notes: "Test workout"
        ))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
