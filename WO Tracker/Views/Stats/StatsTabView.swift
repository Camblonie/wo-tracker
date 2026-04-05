//
//  StatsTabView.swift
//  WO Tracker
//
//  Main container for the stats tab
//

import SwiftUI
import SwiftData

struct StatsTabView: View {
    var body: some View {
        NavigationStack {
            StatsDashboardView()
                .navigationTitle("Stats")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            NavigationLink {
                                PersonalRecordsView()
                            } label: {
                                Label("Personal Records", systemImage: "trophy")
                            }
                            
                            NavigationLink {
                                ExerciseSelectionForProgress()
                            } label: {
                                Label("Exercise Progress", systemImage: "chart.line.uptrend.xyaxis")
                            }
                            
                            Divider()
                            
                            NavigationLink {
                                DataExportView()
                            } label: {
                                Label("Data Export", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
        }
    }
}

// Helper view for selecting exercise to view progress
struct ExerciseSelectionForProgress: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section("Select Exercise") {
                ForEach(exercises) { exercise in
                    NavigationLink {
                        ExerciseProgressView(exercise: exercise)
                    } label: {
                        HStack {
                            Circle()
                                .fill(categoryColor(exercise.category))
                                .frame(width: 10, height: 10)
                            
                            Text(exercise.name)
                                .font(.body)
                            
                            Spacer()
                            
                            if let logCount = exercise.logs?.count, logCount > 0 {
                                Text("\(logCount) sessions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Exercise Progress")
        .navigationBarTitleDisplayMode(.inline)
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

#Preview {
    StatsTabView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
