//
//  ExerciseDetailView.swift
//  WO Tracker
//
//  Detailed view for a single exercise with history and stats
//

import SwiftUI
import SwiftData
import Charts

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let exercise: Exercise
    
    @Query private var workoutLogs: [WorkoutLog]
    @State private var showingDeleteConfirmation = false
    
    init(exercise: Exercise) {
        self.exercise = exercise
        
        // Initialize query to fetch logs for this exercise
        let exerciseID = exercise.id
        _workoutLogs = Query(
            filter: #Predicate { $0.exercise?.id == exerciseID },
            sort: \.date,
            order: .forward
        )
    }
    
    // Personal record
    var personalRecord: Double {
        workoutLogs.map(\.weight).max() ?? 0
    }
    
    // Total volume all time
    var totalVolume: Double {
        workoutLogs.reduce(0) { $0 + ($1.weight * Double($1.reps) * Double($1.sets)) }
    }
    
    // Times performed
    var timesPerformed: Int {
        workoutLogs.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: exercise.category.icon)
                            .font(.largeTitle)
                            .foregroundColor(categoryColor)
                        
                        Text(exercise.category.rawValue)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(categoryColor)
                    }
                    
                    Text(exercise.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Muscle groups
                if !exercise.muscleGroups.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(exercise.muscleGroupsArray, id: \.self) { muscle in
                            Text(muscle)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(categoryColor.opacity(0.15))
                                .foregroundColor(categoryColor)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Instructions
                if let instructions = exercise.instructions {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.headline)
                        
                        Text(instructions)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Stats cards
                HStack(spacing: 12) {
                    StatCard(
                        title: "Personal Record",
                        value: personalRecord > 0 ? String(format: "%.1f", personalRecord) : "-",
                        unit: "lbs",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Times Done",
                        value: "\(timesPerformed)",
                        unit: "sessions",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                // Progress Chart
                if !workoutLogs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weight Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        SimpleProgressChart(logs: workoutLogs)
                            .frame(height: 200)
                            .padding(.horizontal)
                    }
                }
                
                // History section
                VStack(alignment: .leading, spacing: 12) {
                    Text("History")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if workoutLogs.isEmpty {
                        Text("No history yet. Start a workout to track your progress!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(workoutLogs.sorted(by: { $0.date > $1.date })) { log in
                                SimpleHistoryRow(log: log)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !exercise.isBuiltIn {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .alert("Delete Exercise?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteExercise()
            }
        } message: {
            Text("This will permanently delete '\(exercise.name)' and all associated history.")
        }
    }
    
    var categoryColor: Color {
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
    
    func deleteExercise() {
        modelContext.delete(exercise)
        dismiss()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SimpleProgressChart: View {
    let logs: [WorkoutLog]
    
    var body: some View {
        Chart(logs) { log in
            LineMark(
                x: .value("Date", log.date, unit: .day),
                y: .value("Weight", log.weight)
            )
            .foregroundStyle(.orange)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", log.date, unit: .day),
                y: .value("Weight", log.weight)
            )
            .foregroundStyle(.orange.opacity(0.1))
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Date", log.date, unit: .day),
                y: .value("Weight", log.weight)
            )
            .foregroundStyle(.orange)
            .symbolSize(50)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct SimpleHistoryRow: View {
    let log: WorkoutLog
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.date, format: .dateTime.month().day().year())
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(log.sets) sets x \(log.reps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(String(format: "%.1f", log.weight)) lbs")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Flow layout for muscle groups
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.positions[index].x + bounds.minX,
                                      y: result.positions[index].y + bounds.minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise(
            name: "Bench Press",
            category: .chest,
            muscleGroups: ["Chest", "Triceps", "Shoulders"],
            isBuiltIn: true,
            instructions: "Lie on bench, grip bar slightly wider than shoulder width. Lower bar to chest, then press up to full extension."
        ))
    }
}
