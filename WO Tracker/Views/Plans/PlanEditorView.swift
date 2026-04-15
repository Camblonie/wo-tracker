//
//  PlanEditorView.swift
//  WO Tracker
//
//  View for creating and editing workout plans
//

import SwiftUI
import SwiftData

struct PlanEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var plan: WorkoutPlan?
    
    @State private var name = ""
    @State private var details = ""
    @State private var estimatedDuration: String = ""
    @State private var movements: [PlannedMovementInput] = []
    
    @State private var showingAddExercise = false
    @State private var exerciseToAdd: Exercise?
    
    private var isEditing: Bool { plan != nil }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(plan: WorkoutPlan? = nil) {
        self.plan = plan
        
        if let plan = plan {
            _name = State(initialValue: plan.name)
            _details = State(initialValue: plan.details ?? "")
            _estimatedDuration = State(initialValue: plan.estimatedDuration.map(String.init) ?? "")
            
            // Convert existing movements to input format
            let inputs = plan.sortedMovements.map { movement in
                PlannedMovementInput(
                    id: movement.id,
                    exercise: movement.exercise,
                    targetSets: movement.targetSets,
                    targetReps: movement.targetReps,
                    targetWeight: movement.targetWeight,
                    restSeconds: movement.restSeconds
                )
            }
            _movements = State(initialValue: inputs)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Plan details section
                Section("Plan Details") {
                    TextField("Plan Name", text: $name)
                    
                    TextField("Description (optional)", text: $details, axis: .vertical)
                        .lineLimit(2...4)
                    
                    HStack {
                        Text("Est. Duration")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("Minutes", text: $estimatedDuration)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                // Exercises section
                Section {
                    if movements.isEmpty {
                        Text("No exercises added yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach($movements) { $movement in
                            MovementEditorRow(movement: $movement, index: movements.firstIndex(where: { $0.id == movement.id }) ?? 0)
                        }
                        .onDelete(perform: deleteMovement)
                        .onMove(perform: moveMovement)
                    }
                    
                    Button {
                        showingAddExercise = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add Exercise")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Exercises (\(movements.count))")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(isEditing ? "Edit Plan" : "New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePlan()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                ExercisePickerView { selectedExercise in
                    addMovement(for: selectedExercise)
                }
            }
        }
    }
    
    private func addMovement(for exercise: Exercise) {
        let newMovement = PlannedMovementInput(
            exercise: exercise,
            targetSets: 3,
            targetReps: 10,
            targetWeight: nil,
            restSeconds: 60
        )
        movements.append(newMovement)
    }
    
    private func deleteMovement(at offsets: IndexSet) {
        movements.remove(atOffsets: offsets)
    }
    
    private func moveMovement(from source: IndexSet, to destination: Int) {
        movements.move(fromOffsets: source, toOffset: destination)
    }
    
    private func savePlan() {
        let duration = Int(estimatedDuration)
        
        if let existingPlan = plan {
            // Update existing plan
            existingPlan.name = name.trimmingCharacters(in: .whitespaces)
            existingPlan.details = details.trimmingCharacters(in: .whitespaces).isEmpty ? nil : details
            existingPlan.estimatedDuration = duration
            
            // Remove old movements
            if let oldMovements = existingPlan.movements {
                for movement in oldMovements {
                    modelContext.delete(movement)
                }
            }
            
            // Add new movements
            for (index, input) in movements.enumerated() {
                let movement = PlannedMovement(
                    orderIndex: index,
                    targetSets: input.targetSets,
                    targetReps: input.targetReps,
                    targetWeight: input.targetWeight,
                    restSeconds: input.restSeconds,
                    exercise: input.exercise,
                    workoutPlan: existingPlan
                )
                modelContext.insert(movement)
            }
        } else {
            // Create new plan
            let newPlan = WorkoutPlan(
                name: name.trimmingCharacters(in: .whitespaces),
                details: details.trimmingCharacters(in: .whitespaces).isEmpty ? nil : details,
                estimatedDuration: duration
            )
            modelContext.insert(newPlan)
            
            // Add movements
            for (index, input) in movements.enumerated() {
                let movement = PlannedMovement(
                    orderIndex: index,
                    targetSets: input.targetSets,
                    targetReps: input.targetReps,
                    targetWeight: input.targetWeight,
                    restSeconds: input.restSeconds,
                    exercise: input.exercise,
                    workoutPlan: newPlan
                )
                modelContext.insert(movement)
            }
        }
        
        dismiss()
    }
}

// MARK: - Supporting Types

struct PlannedMovementInput: Identifiable {
    let id: UUID
    var exercise: Exercise?
    var targetSets: Int
    var targetReps: Int
    var targetWeight: Double?
    var restSeconds: Int?
    
    init(
        id: UUID = UUID(),
        exercise: Exercise?,
        targetSets: Int,
        targetReps: Int,
        targetWeight: Double?,
        restSeconds: Int?
    ) {
        self.id = id
        self.exercise = exercise
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restSeconds = restSeconds
    }
}

struct MovementEditorRow: View {
    @Binding var movement: PlannedMovementInput
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(categoryColor)
                    .clipShape(Circle())
                
                if let exercise = movement.exercise {
                    Text(exercise.name)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Sets control
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        Button {
                            if movement.targetSets > 1 {
                                movement.targetSets -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        
                        Text("\(movement.targetSets)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(minWidth: 25)
                        
                        Button {
                            if movement.targetSets < 20 {
                                movement.targetSets += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 70)
                
                Divider()
                    .frame(height: 30)
                
                // Reps control
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        Button {
                            if movement.targetReps > 1 {
                                movement.targetReps -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        
                        Text("\(movement.targetReps)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(minWidth: 25)
                        
                        Button {
                            if movement.targetReps < 100 {
                                movement.targetReps += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 70)
                
                Divider()
                    .frame(height: 30)
                
                // Weight field
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight (lbs)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Optional", value: $movement.targetWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.subheadline)
                        .frame(width: 60)
                }
                
                Divider()
                    .frame(height: 30)
                
                // Rest field
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest (s)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Rest", value: $movement.restSeconds, format: .number)
                        .keyboardType(.numberPad)
                        .font(.subheadline)
                        .frame(width: 50)
                }
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

// MARK: - Exercise Picker View

struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (Exercise) -> Void
    
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    
    var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil ||
                exercise.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil, color: .gray) {
                            selectedCategory = nil
                        }
                        
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            FilterChip(title: category.rawValue, isSelected: selectedCategory == category, color: categoryColor(category)) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                // Exercises list
                ForEach(filteredExercises) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        HStack {
                            Circle()
                                .fill(categoryColor(exercise.category))
                                .frame(width: 10, height: 10)
                            
                            Text(exercise.name)
                                .font(.body)
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func categoryColor(_ category: ExerciseCategory) -> Color {
        switch category {
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

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.15))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PlanEditorView()
        .modelContainer(for: WorkoutPlan.self, inMemory: true)
}
