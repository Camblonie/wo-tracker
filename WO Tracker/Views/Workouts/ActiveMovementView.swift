//
//  ActiveMovementView.swift
//  WO Tracker
//
//  View for editing a single exercise during active workout
//

import SwiftUI

struct ActiveMovementView: View {
    @Binding var movement: ActiveMovementInput
    let onPrevious: () -> Void
    let onNext: () -> Void
    let isFirst: Bool
    let isLast: Bool
    
    @State private var showingPreviousPerformance = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Exercise header
                VStack(spacing: 8) {
                    if let exercise = movement.exercise {
                        HStack {
                            Image(systemName: exercise.category.icon)
                                .font(.title2)
                                .foregroundColor(categoryColor)
                            
                            Text(exercise.category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(categoryColor)
                        }
                        
                        Text(exercise.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Unknown Exercise")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                .padding(.top, 8)
                
                // Target info
                HStack(spacing: 20) {
                    TargetBadge(label: "Target Sets", value: "\(movement.targetSets)")
                    TargetBadge(label: "Target Reps", value: "\(movement.targetReps)")
                    if let weight = movement.targetWeight {
                        TargetBadge(label: "Target Weight", value: "\(String(format: "%.0f", weight))")
                    }
                }
                
                // Previous performance toggle
                Button {
                    showingPreviousPerformance.toggle()
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Show Previous Performance")
                            .font(.subheadline)
                    }
                    .foregroundColor(.blue)
                }
                
                // Sets section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sets")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 10) {
                        ForEach($movement.sets) { $set in
                            SetInputRow(
                                set: $set,
                                setNumber: set.setNumber,
                                previousWeight: showingPreviousPerformance ? movement.targetWeight : nil,
                                previousReps: showingPreviousPerformance ? movement.targetReps : nil,
                                onComplete: {
                                    checkMovementCompletion()
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Add set button
                    Button {
                        addSet()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Set")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                // Notes field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("Add notes about this exercise...", text: $movement.notes.bound, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                // Navigation buttons
                HStack(spacing: 16) {
                    Button {
                        onPrevious()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                    }
                    .disabled(isFirst)
                    .opacity(isFirst ? 0.5 : 1)
                    
                    Button {
                        onNext()
                    } label: {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    .disabled(isLast)
                    .opacity(isLast ? 0.5 : 1)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }
    
    private var categoryColor: Color {
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
    
    private func addSet() {
        let newSetNumber = movement.sets.count + 1
        let lastSet = movement.sets.last
        let newSet = ExerciseSetInput(
            setNumber: newSetNumber,
            reps: lastSet?.reps ?? movement.targetReps,
            weight: lastSet?.weight ?? movement.targetWeight ?? 0
        )
        movement.sets.append(newSet)
    }
    
    private func checkMovementCompletion() {
        movement.isCompleted = movement.sets.contains { $0.isCompleted }
    }
}

struct TargetBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

// Binding extension for optional strings
extension Binding where Value == String? {
    var bound: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

#Preview {
    ActiveMovementView(
        movement: .constant(ActiveMovementInput(
            orderIndex: 0,
            exercise: Exercise(name: "Bench Press", category: .chest, muscleGroups: ["Chest", "Triceps"], isBuiltIn: true),
            targetSets: 3,
            targetReps: 10,
            targetWeight: 135,
            sets: [
                ExerciseSetInput(setNumber: 1, reps: 10, weight: 135),
                ExerciseSetInput(setNumber: 2, reps: 10, weight: 135),
                ExerciseSetInput(setNumber: 3, reps: 10, weight: 135)
            ]
        )),
        onPrevious: {},
        onNext: {},
        isFirst: true,
        isLast: false
    )
}
