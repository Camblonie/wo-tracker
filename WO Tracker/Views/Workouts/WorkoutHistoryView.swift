//
//  WorkoutHistoryView.swift
//  WO Tracker
//
//  View for displaying past workout sessions
//

import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        filter: #Predicate<WorkoutSession> { $0.statusRaw == "Completed" },
        sort: \.startedAt,
        order: .reverse
    ) private var sessions: [WorkoutSession]
    
    var groupedSessions: [(String, [WorkoutSession])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        let grouped = Dictionary(grouping: sessions) { session -> String in
            if calendar.isDateInToday(session.startedAt) {
                return "Today"
            } else if calendar.isDateInYesterday(session.startedAt) {
                return "Yesterday"
            } else {
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: session.startedAt)
            }
        }
        
        return grouped.sorted { group1, group2 in
            // Sort by date (Today > Yesterday > older months)
            let date1 = sessions.first { $0.startedAt == group1.1.first?.startedAt }?.startedAt ?? Date.distantPast
            let date2 = sessions.first { $0.startedAt == group2.1.first?.startedAt }?.startedAt ?? Date.distantPast
            return date1 > date2
        }
    }
    
    var body: some View {
        List {
            if sessions.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Workouts Yet")
                            .font(.headline)
                        
                        Text("Complete your first workout to see it here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(groupedSessions, id: \.0) { section, sectionSessions in
                    Section(section) {
                        ForEach(sectionSessions) { session in
                            SessionRow(session: session)
                        }
                        .onDelete { indexSet in
                            deleteSessions(in: sectionSessions, at: indexSet)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("History")
    }
    
    private func deleteSessions(in sectionSessions: [WorkoutSession], at offsets: IndexSet) {
        for index in offsets {
            let session = sectionSessions[index]
            modelContext.delete(session)
        }
    }
}

struct SessionRow: View {
    let session: WorkoutSession
    
    var body: some View {
        NavigationLink {
            SessionDetailView(session: session)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let plan = session.plan {
                        Text(plan.name)
                            .font(.headline)
                    } else {
                        Text("Free Workout")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    if let duration = session.durationMinutes {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("\(duration)m")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    // Exercise count
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell")
                            .font(.caption)
                        Text("\(session.completedMovements?.count ?? 0) exercises")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    
                    // Total volume
                    let totalVolume = (session.completedMovements ?? []).reduce(0) { $0 + $1.totalVolume }
                    if totalVolume > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "scalemass")
                                .font(.caption)
                            Text("\(Int(totalVolume)) lbs")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                    
                    // Time
                    Text(session.startedAt, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct SessionDetailView: View {
    let session: WorkoutSession
    
    var totalVolume: Double {
        (session.completedMovements ?? []).reduce(0) { $0 + $1.totalVolume }
    }
    
    var body: some View {
        List {
            // Header section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if let plan = session.plan {
                        Text(plan.name)
                            .font(.title)
                            .fontWeight(.bold)
                    } else {
                        Text("Free Workout")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    HStack(spacing: 16) {
                        StatBadge(
                            icon: "calendar",
                            label: "Date",
                            value: session.startedAt.formatted(date: .abbreviated, time: .omitted)
                        )
                        
                        if let duration = session.durationMinutes {
                            StatBadge(
                                icon: "clock",
                                label: "Duration",
                                value: "\(duration) min"
                            )
                        }
                    }
                    
                    if totalVolume > 0 {
                        StatBadge(
                            icon: "scalemass.fill",
                            label: "Total Volume",
                            value: "\(Int(totalVolume)) lbs"
                        )
                        .foregroundColor(.green)
                    }
                    
                    if let notes = session.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Exercises section
            Section("Exercises") {
                if let movements = session.completedMovements?.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                    ForEach(movements) { movement in
                        CompletedMovementDetailRow(movement: movement)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
}

struct CompletedMovementDetailRow: View {
    let movement: CompletedMovement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let exercise = movement.exercise {
                    Text(exercise.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 10, height: 10)
                } else {
                    Text("Unknown Exercise")
                        .font(.headline)
                }
            }
            
            // Sets performed
            VStack(alignment: .leading, spacing: 4) {
                ForEach(movement.sortedSets) { set in
                    HStack {
                        Text("Set \(set.setNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 45, alignment: .leading)
                        
                        if set.isCompleted {
                            Text("\(set.reps) reps × \(String(format: "%.1f", set.weight)) lbs")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Text("Not completed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
            }
            
            // Volume summary
            if movement.totalVolume > 0 {
                HStack {
                    Spacer()
                    Text("Volume: \(Int(movement.totalVolume)) lbs")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
            
            if let notes = movement.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
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
        WorkoutHistoryView()
    }
}
