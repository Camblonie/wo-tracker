//
//  WorkoutsTabView.swift
//  WO Tracker
//
//  Main container for the workouts tab with start options and history
//

import SwiftUI
import SwiftData

struct WorkoutsTabView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    
    @State private var showingActiveWorkout = false
    @State private var selectedPlan: WorkoutPlan?
    @State private var showingPlanPicker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick start section
                QuickStartSection(
                    onFreeWorkout: {
                        selectedPlan = nil
                        showingActiveWorkout = true
                    },
                    onFromPlan: {
                        showingPlanPicker = true
                    }
                )
                
                Divider()
                
                // Recent history preview
                RecentHistorySection()
                
                Spacer()
            }
            .navigationTitle("Workouts")
            .sheet(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView(plan: selectedPlan)
            }
            .sheet(isPresented: $showingPlanPicker) {
                PlanPickerView(plans: plans) { plan in
                    selectedPlan = plan
                    showingPlanPicker = false
                    showingActiveWorkout = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct QuickStartSection: View {
    let onFreeWorkout: () -> Void
    let onFromPlan: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Start Workout")
                .font(.title2)
                .fontWeight(.bold)
            
            // Quick start buttons
            VStack(spacing: 12) {
                Button {
                    onFreeWorkout()
                } label: {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quick Start")
                                .font(.headline)
                            Text("Start logging immediately")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                Button {
                    onFromPlan()
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("From Plan")
                                .font(.headline)
                            Text("Use a saved workout plan")
                                .font(.caption)
                                .foregroundColor(.primary.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }
}

struct RecentHistorySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    WorkoutHistoryView()
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Preview of recent workouts
            WorkoutHistoryPreview()
        }
        .padding(.top, 16)
        .background(Color(.systemGray6))
    }
}

struct WorkoutHistoryPreview: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.statusRaw == "Completed" },
        sort: \.startedAt,
        order: .reverse
    ) private var recentSessions: [WorkoutSession]
    
    var previewSessions: [WorkoutSession] {
        Array(recentSessions.prefix(3))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if previewSessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No workouts yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Complete your first workout above!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 40)
            } else {
                ForEach(previewSessions) { session in
                    PreviewSessionRow(session: session)
                }
                
                if recentSessions.count > 3 {
                    Text("+ \(recentSessions.count - 3) more workouts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
}

struct PreviewSessionRow: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let plan = session.plan {
                    Text(plan.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                } else {
                    Text("Free Workout")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text(session.startedAt, format: .dateTime.weekday().month().day())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let duration = session.durationMinutes {
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(duration)m")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct PlanPickerView: View {
    let plans: [WorkoutPlan]
    let onSelect: (WorkoutPlan) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if plans.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            Text("No Workout Plans")
                                .font(.headline)
                            
                            Text("Create a workout plan first to use this feature.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    Section("Select a Plan") {
                        ForEach(plans) { plan in
                            Button {
                                onSelect(plan)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let details = plan.details, !details.isEmpty {
                                        Text(details)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    HStack {
                                        Text("\(plan.movements?.count ?? 0) exercises")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        
                                        if let duration = plan.estimatedDuration {
                                            Text("• \(duration) min")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Start From Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutsTabView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
