//
//  ExerciseProgressView.swift
//  WO Tracker
//
//  Detailed progress view for a specific exercise with charts
//

import SwiftUI
import SwiftData
import Charts

struct ExerciseProgressView: View {
    let exercise: Exercise
    
    @Query private var logs: [WorkoutLog]
    @State private var selectedTimeRange: TimeRange = .all
    @State private var chartType: ChartType = .weight
    
    init(exercise: Exercise) {
        self.exercise = exercise
        let exerciseID = exercise.id
        _logs = Query(
            filter: #Predicate { $0.exercise?.id == exerciseID },
            sort: \.date,
            order: .forward
        )
    }
    
    enum TimeRange: String, CaseIterable {
        case week = "1W"
        case month = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case year = "1Y"
        case all = "All"
        
        var calendarComponent: Calendar.Component? {
            switch self {
            case .week: return .weekOfYear
            case .month: return .month
            case .threeMonths: return nil // Special handling
            case .sixMonths: return nil // Special handling
            case .year: return .year
            case .all: return nil
            }
        }
        
        var value: Int? {
            switch self {
            case .week: return -1
            case .month: return -1
            case .threeMonths: return -3
            case .sixMonths: return -6
            case .year: return -1
            case .all: return nil
            }
        }
    }
    
    enum ChartType: String, CaseIterable {
        case weight = "Weight"
        case volume = "Volume"
        case reps = "Reps"
    }
    
    var filteredLogs: [WorkoutLog] {
        guard selectedTimeRange != .all else { return logs }
        
        let calendar = Calendar.current
        let now = Date()
        
        return logs.filter { log in
            switch selectedTimeRange {
            case .week:
                return calendar.isDate(log.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(log.date, equalTo: now, toGranularity: .month)
            case .threeMonths:
                let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
                return log.date >= threeMonthsAgo
            case .sixMonths:
                let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now)!
                return log.date >= sixMonthsAgo
            case .year:
                return calendar.isDate(log.date, equalTo: now, toGranularity: .year)
            case .all:
                return true
            }
        }
    }
    
    var personalRecord: Double {
        logs.map { $0.weight }.max() ?? 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
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
                }
                .padding(.top, 8)
                
                // Stats row
                HStack(spacing: 12) {
                    StatBox(
                        title: "Personal Best",
                        value: personalRecord > 0 ? String(format: "%.1f", personalRecord) : "-",
                        unit: "lbs",
                        color: .yellow
                    )
                    
                    StatBox(
                        title: "Total Sessions",
                        value: "\(logs.count)",
                        unit: "times",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                // Chart section
                VStack(spacing: 12) {
                    // Time range selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Button {
                                    selectedTimeRange = range
                                } label: {
                                    Text(range.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(selectedTimeRange == range ? .semibold : .regular)
                                        .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedTimeRange == range ? Color.orange : Color(.systemGray5))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Chart type selector
                    Picker("Chart Type", selection: $chartType) {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Chart
                    if filteredLogs.isEmpty {
                        Text("No data for selected time range")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    } else {
                        ProgressChart(logs: filteredLogs, chartType: chartType)
                            .frame(height: 250)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // History table
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("History")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(filteredLogs.count) entries")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    LazyVStack(spacing: 8) {
                        ForEach(filteredLogs.sorted(by: { $0.date > $1.date })) { log in
                            HistoryRow(log: log)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
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
}

struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
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

struct ProgressChart: View {
    let logs: [WorkoutLog]
    let chartType: ExerciseProgressView.ChartType
    
    var body: some View {
        Chart(logs) { log in
            switch chartType {
            case .weight:
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
                .symbolSize(60)
                
            case .volume:
                let volume = log.weight * Double(log.reps) * Double(log.sets)
                BarMark(
                    x: .value("Date", log.date, unit: .day),
                    y: .value("Volume", volume)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
                
            case .reps:
                BarMark(
                    x: .value("Date", log.date, unit: .day),
                    y: .value("Reps", log.reps * log.sets)
                )
                .foregroundStyle(.green.gradient)
                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct HistoryRow: View {
    let log: WorkoutLog
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.date, format: .dateTime.month().day().year())
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(log.sets) sets × \(log.reps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.1f", log.weight)) lbs")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                let volume = Int(log.weight * Double(log.reps) * Double(log.sets))
                Text("\(volume) vol")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ExerciseProgressView(exercise: Exercise(
            name: "Bench Press",
            category: .chest,
            muscleGroups: ["Chest", "Triceps"],
            isBuiltIn: true
        ))
    }
}
