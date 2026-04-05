//
//  AddExerciseView.swift
//  WO Tracker
//
//  View for adding custom exercises
//

import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedCategory: ExerciseCategory = .chest
    @State private var muscleGroups: [String] = []
    @State private var newMuscleGroup = ""
    @State private var instructions = ""
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $name)
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section("Muscle Groups") {
                    // Current muscle groups
                    if !muscleGroups.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(muscleGroups, id: \.self) { muscle in
                                HStack(spacing: 4) {
                                    Text(muscle)
                                        .font(.caption)
                                    
                                    Button {
                                        removeMuscleGroup(muscle)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // Add new muscle group
                    HStack {
                        TextField("Add muscle group", text: $newMuscleGroup)
                        
                        Button("Add") {
                            addMuscleGroup()
                        }
                        .disabled(newMuscleGroup.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                
                Section("Instructions") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExercise()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    func addMuscleGroup() {
        let trimmed = newMuscleGroup.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !muscleGroups.contains(trimmed) {
            muscleGroups.append(trimmed)
            newMuscleGroup = ""
        }
    }
    
    func removeMuscleGroup(_ muscle: String) {
        muscleGroups.removeAll { $0 == muscle }
    }
    
    func saveExercise() {
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            category: selectedCategory,
            muscleGroups: muscleGroups,
            isBuiltIn: false,
            instructions: instructions.trimmingCharacters(in: .whitespaces).isEmpty ? nil : instructions
        )
        
        modelContext.insert(exercise)
        dismiss()
    }
}

#Preview {
    AddExerciseView()
}
