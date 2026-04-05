//
//  StatsDashboardView.swift
//  WO Tracker
//
//  Main dashboard with workout statistics overview
//

import SwiftUI
import SwiftData
import Charts

struct StatsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<WorkoutSession> { $0.statusRaw == "Completed" })
    private var sessions: [WorkoutSession]
    
    @Query(sort: \WorkoutLog.date, order: .reverse)
    private var allLogs: [WorkoutLog]
    
    // Computed stats
    var totalWorkouts: Int {
        sessions.count
    }
    
    var totalVolume: Double {
        allLogs.reduce(0) { $0 + ($1.weight * Double($1.reps) * Double($1.sets)) }
    }
    
    var thisWeekWorkouts: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date.distantPast
        return sessions.filter { $0.startedAt >= weekAgo }.count
    }
    
    var currentStreak: Int {
        calculateStreak()
    }
    
    var personalRecords: Int {
        calculatePRCount()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    DashboardStatCard(
                        title: "Total Workouts",
                        value: "\(totalWorkouts)",
                        icon: "figure.strengthtraining.traditional",
                        color: .blue
                    )
                    
                    DashboardStatCard(
                        title: "This Week",
                        value: "\(thisWeekWorkouts)",
                        icon: "calendar.badge.clock",
                        color: .orange
                    )
                    
                    DashboardStatCard(
                        title: "Current Streak",
                        value: "\(currentStreak) days",
                        icon: "flame.fill",
                        color: .red
                    )
                    
                    DashboardStatCard(
                        title: "Personal Records",
                        value: "\(personalRecords)",
                        icon: "trophy.fill",
                        color: .yellow
                    )
                }
                .padding(.horizontal)
                
                // Total volume card
                VolumeCard(totalVolume: totalVolume)
                    .padding(.horizontal)
                
                // Weekly activity chart
                WeeklyActivityChart(sessions: sessions)
                    .padding(.horizontal)
                
                // Recent PRs section
                if !recentPRs.isEmpty {
                    RecentPRsSection(logs: recentPRs)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }
    
    private var recentPRs: [WorkoutLog] {
        // Get logs that are personal records for their exercise
        Array(allLogs.prefix(20))
    }
    
    private func calculateStreak() -> Int {
        guard !sessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDates = sessions.map { $0.startedAt }.sorted(by: >)
        
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        for date in sortedDates {
            let sessionDay = calendar.startOfDay(for: date)
            
            if calendar.isDate(sessionDay, inSameDayAs: checkDate) {
                if streak == 0 { streak = 1 }
            } else if calendar.isDate(sessionDay, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: checkDate)!) {
                streak += 1
                checkDate = sessionDay
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculatePRCount() -> Int {
        // Count exercises where the max weight was achieved
        let groupedByExercise = Dictionary(grouping: allLogs) { $0.exercise?.id }
        var prCount = 0
        
        for (_, logs) in groupedByExercise {
            guard !logs.isEmpty else { continue }
            let maxWeight = logs.map { $0.weight }.max() ?? 0
            let prLogs = logs.filter { $0.weight == maxWeight }
            prCount += prLogs.count
        }
        
        return prCount
    }
}

// MARK: - Supporting Views

struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct VolumeCard: View {
    let totalVolume: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Total Volume Lifted")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(formattedVolume)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.green)
                
                Text("lbs")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    var formattedVolume: String {
        if totalVolume >= 1_000_000 {
            return String(format: "%.1fM", totalVolume / 1_000_000)
        } else if totalVolume >= 1000 {
            return String(format: "%.1fK", totalVolume / 1000)
        } else {
            return String(format: "%.0f", totalVolume)
        }
    }
}

struct WeeklyActivityChart: View {
    let sessions: [WorkoutSession]
    
    var weeklyData: [(day: String, count: Int)] {
        let calendar = Calendar.current
        let today = Date()
        let weekdaySymbols = calendar.shortWeekdaySymbols
        
        var data: [(String, Int)] = []
        
        for offset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let count = sessions.filter { session in
                session.startedAt >= dayStart && session.startedAt < dayEnd
            }.count
            
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let dayName = weekdaySymbols[weekdayIndex]
            
            data.append((dayName, count))
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.headline)
            
            Chart(weeklyData, id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Workouts", item.count)
                )
                .foregroundStyle(.orange.gradient)
                .cornerRadius(4)
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(position: .leading, values: .stride(by: 1))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentPRsSection: View {
    let logs: [WorkoutLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(logs.prefix(5)) { log in
                    if let exercise = log.exercise {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("\(log.sets) sets × \(log.reps) reps @ \(String(format: "%.1f", log.weight)) lbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(log.date, format: .dateTime.month().day())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StatsDashboardView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
