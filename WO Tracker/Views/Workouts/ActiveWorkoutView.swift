//
//  ActiveWorkoutView.swift
//  WO Tracker
//
//  Main view for logging an active workout session
//

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let plan: WorkoutPlan?
    
    @State private var session: WorkoutSession?
    @State private var movements: [ActiveMovementInput] = []
    @State private var currentMovementIndex = 0
    @State private var showingCancelConfirmation = false
    @State private var showingFinishConfirmation = false
    @State private var showingAddExercise = false
    @State private var showingRestTimer = false
    @State private var workoutNotes = ""
    @State private var timer: Timer?
    @State private var elapsedSeconds = 0
    
    init(plan: WorkoutPlan? = nil) {
        self.plan = plan
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with timer
                WorkoutHeader(
                    elapsedTime: formatTime(elapsedSeconds),
                    exerciseCount: movements.count,
                    completedCount: movements.filter { $0.isCompleted }.count
                )
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Movement selector
                if movements.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(movements.enumerated()), id: \.element.id) { index, movement in
                                MovementTab(
                                    index: index,
                                    name: movement.exercise?.name ?? "Exercise",
                                    isActive: index == currentMovementIndex,
                                    isCompleted: movement.isCompleted
                                ) {
                                    withAnimation {
                                        currentMovementIndex = index
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemGray6))
                }
                
                // Current movement editor
                if movements.indices.contains(currentMovementIndex) {
                    ActiveMovementView(
                        movement: $movements[currentMovementIndex],
                        onPrevious: {
                            if currentMovementIndex > 0 {
                                withAnimation {
                                    currentMovementIndex -= 1
                                }
                            }
                        },
                        onNext: {
                            if currentMovementIndex < movements.count - 1 {
                                withAnimation {
                                    currentMovementIndex += 1
                                }
                            }
                        },
                        isFirst: currentMovementIndex == 0,
                        isLast: currentMovementIndex == movements.count - 1
                    )
                }
                
                Spacer()
                
                // Bottom actions
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            showingCancelConfirmation = true
                        } label: {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        Button {
                            showingFinishConfirmation = true
                        } label: {
                            Text("Finish Workout")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(canFinish ? Color.green : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(!canFinish)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle(plan?.name ?? "Free Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            addExercise()
                        } label: {
                            Label("Add Exercise", systemImage: "plus")
                        }
                        
                        Button {
                            showingRestTimer = true
                        } label: {
                            Label("Rest Timer", systemImage: "timer")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                initializeWorkout()
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .alert("Cancel Workout?", isPresented: $showingCancelConfirmation) {
                Button("Continue", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    cancelWorkout()
                }
            } message: {
                Text("Your progress will not be saved.")
            }
            .alert("Finish Workout?", isPresented: $showingFinishConfirmation) {
                Button("Continue", role: .cancel) { }
                Button("Save", role: .destructive) {
                    finishWorkout()
                }
            } message: {
                Text("Save this workout to your history?")
            }
            .sheet(isPresented: $showingAddExercise) {
                ExercisePickerView { exercise in
                    addMovement(for: exercise)
                }
            }
            .sheet(isPresented: $showingRestTimer) {
                RestTimerView(isPresented: $showingRestTimer)
            }
        }
    }
    
    private var canFinish: Bool {
        movements.contains { $0.sets.contains { $0.isCompleted } }
    }
    
    private func initializeWorkout() {
        // Create session
        let newSession = WorkoutSession(
            plan: plan,
            startedAt: Date(),
            status: .inProgress
        )
        modelContext.insert(newSession)
        session = newSession
        
        // Create history service for looking up previous performances
        let historyService = WorkoutHistoryService(modelContext: modelContext)
        
        // Initialize movements from plan or start empty
        if let plan = plan {
            movements = plan.sortedMovements.enumerated().map { index, planned in
                // Get sets pre-populated from last workout or use plan defaults
                let sets = historyService.createSetsFromHistory(
                    targetSets: planned.targetSets,
                    targetReps: planned.targetReps,
                    targetWeight: planned.targetWeight,
                    for: planned.exercise
                )
                
                return ActiveMovementInput(
                    orderIndex: index,
                    exercise: planned.exercise,
                    targetSets: planned.targetSets,
                    targetReps: planned.targetReps,
                    targetWeight: planned.targetWeight,
                    sets: sets
                )
            }
        }
    }
    
    private func addMovement(for exercise: Exercise) {
        // Create history service for looking up previous performances
        let historyService = WorkoutHistoryService(modelContext: modelContext)
        
        // Get sets pre-populated from last workout or use defaults
        let sets = historyService.createSetsFromHistory(
            targetSets: 3,
            targetReps: 10,
            targetWeight: 0,
            for: exercise
        )
        
        let newMovement = ActiveMovementInput(
            orderIndex: movements.count,
            exercise: exercise,
            targetSets: 3,
            targetReps: 10,
            sets: sets
        )
        movements.append(newMovement)
        
        // Navigate to the new movement
        withAnimation {
            currentMovementIndex = movements.count - 1
        }
    }
    
    private func addExercise() {
        showingAddExercise = true
    }
    
    private func finishWorkout() {
        guard let session = session else { return }
        
        // Save all completed movements and sets
        for movementInput in movements {
            let completedMovement = CompletedMovement(
                exercise: movementInput.exercise,
                session: session,
                orderIndex: movementInput.orderIndex,
                startedAt: Date(),
                completedAt: movementInput.isCompleted ? Date() : nil,
                notes: movementInput.notes
            )
            modelContext.insert(completedMovement)
            
            // Save sets
            for setInput in movementInput.sets {
                let exerciseSet = setInput.toExerciseSet(for: completedMovement)
                modelContext.insert(exerciseSet)
                
                // Also create a workout log for history
                if setInput.isCompleted {
                    let log = WorkoutLog(
                        exercise: movementInput.exercise,
                        date: Date(),
                        weight: setInput.weight,
                        reps: setInput.reps,
                        sets: 1,
                        sessionID: session.id
                    )
                    modelContext.insert(log)
                }
            }
        }
        
        // Update session
        session.completedAt = Date()
        session.status = .completed
        session.notes = workoutNotes.isEmpty ? nil : workoutNotes
        
        // Update plan last performed
        if let plan = plan {
            plan.lastPerformed = Date()
        }
        
        dismiss()
    }
    
    private func cancelWorkout() {
        if let session = session {
            session.status = .cancelled
        }
        dismiss()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - Supporting Views

struct WorkoutHeader: View {
    let elapsedTime: String
    let exerciseCount: Int
    let completedCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(elapsedTime)
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(completedCount)/\(exerciseCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
        }
    }
}

struct MovementTab: View {
    let index: Int
    let name: String
    let isActive: Bool
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isActive || isCompleted ? .white : .secondary)
                
                Text(name)
                    .font(.caption2)
                    .fontWeight(isActive ? .semibold : .regular)
                    .lineLimit(1)
                    .foregroundColor(isActive || isCompleted ? .white : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 80)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
    
    var backgroundColor: Color {
        if isActive {
            return .orange
        } else if isCompleted {
            return .green
        } else {
            return Color(.systemBackground)
        }
    }
}

// MARK: - Active Movement Input

struct ActiveMovementInput: Identifiable {
    let id = UUID()
    var orderIndex: Int
    var exercise: Exercise?
    var targetSets: Int
    var targetReps: Int
    var targetWeight: Double?
    var sets: [ExerciseSetInput]
    var notes: String?
    var isCompleted: Bool
    
    init(
        orderIndex: Int,
        exercise: Exercise?,
        targetSets: Int,
        targetReps: Int,
        targetWeight: Double? = nil,
        sets: [ExerciseSetInput] = [],
        notes: String? = nil,
        isCompleted: Bool = false
    ) {
        self.orderIndex = orderIndex
        self.exercise = exercise
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.sets = sets
        self.notes = notes
        self.isCompleted = isCompleted
    }
}

#Preview {
    ActiveWorkoutView()
}
