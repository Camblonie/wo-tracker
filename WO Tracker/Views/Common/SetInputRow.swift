//
//  SetInputRow.swift
//  WO Tracker
//
//  Reusable component for logging individual sets
//

import SwiftUI

struct SetInputRow: View {
    @Binding var set: ExerciseSetInput
    let setNumber: Int
    let previousWeight: Double?
    let previousReps: Int?
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("\(setNumber)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(set.isCompleted ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(set.isCompleted ? Color.green : Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Previous performance hint
            if let prevWeight = previousWeight, let prevReps = previousReps {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Previous")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", prevWeight)) × \(prevReps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 70)
            }
            
            Divider()
                .frame(height: 40)
            
            // Weight input
            VStack(alignment: .leading, spacing: 2) {
                Text("Weight")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(spacing: 2) {
                    TextField("0", value: $set.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(width: 50)
                        .multilineTextAlignment(.trailing)
                    Text("lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .frame(height: 40)
            
            // Reps input
            VStack(alignment: .leading, spacing: 2) {
                Text("Reps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                TextField("0", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .font(.body)
                    .fontWeight(.medium)
                    .frame(width: 40)
                    .multilineTextAlignment(.trailing)
            }
            
            Spacer()
            
            // Complete checkbox
            Button {
                set.isCompleted.toggle()
                if set.isCompleted {
                    set.completedAt = Date()
                    onComplete()
                } else {
                    set.completedAt = nil
                }
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(set.isCompleted ? .green : .gray)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Input struct for active workout
struct ExerciseSetInput: Identifiable {
    let id: UUID
    var setNumber: Int
    var reps: Int
    var weight: Double
    var isCompleted: Bool
    var isWarmup: Bool
    var isToFailure: Bool
    var rpe: Int?
    var notes: String?
    var completedAt: Date?
    
    init(
        id: UUID = UUID(),
        setNumber: Int,
        reps: Int = 0,
        weight: Double = 0,
        isCompleted: Bool = false,
        isWarmup: Bool = false,
        isToFailure: Bool = false,
        rpe: Int? = nil,
        notes: String? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
        self.isWarmup = isWarmup
        self.isToFailure = isToFailure
        self.rpe = rpe
        self.notes = notes
        self.completedAt = completedAt
    }
    
    // Convert to ExerciseSet model
    func toExerciseSet(for completedMovement: CompletedMovement) -> ExerciseSet {
        ExerciseSet(
            id: id,
            setNumber: setNumber,
            reps: reps,
            weight: weight,
            isCompleted: isCompleted,
            isWarmup: isWarmup,
            isToFailure: isToFailure,
            rpe: rpe,
            notes: notes,
            completedAt: completedAt,
            completedMovement: completedMovement
        )
    }
}

#Preview {
    SetInputRow(
        set: .constant(ExerciseSetInput(setNumber: 1, reps: 10, weight: 135)),
        setNumber: 1,
        previousWeight: 130,
        previousReps: 10,
        onComplete: {}
    )
    .padding()
}
