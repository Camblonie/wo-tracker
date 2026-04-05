//
//  PersonalRecordsView.swift
//  WO Tracker
//
//  View for tracking all personal records
//

import SwiftUI
import SwiftData

struct PersonalRecordsView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    @State private var selectedCategory: ExerciseCategory?
    
    var exercisesWithPRs: [(exercise: Exercise, maxWeight: Double, maxVolume: Double, prDate: Date?)] {
        let filtered = selectedCategory == nil ? exercises : exercises.filter { $0.category == selectedCategory }
        
        return filtered.compactMap { exercise in
            guard let logs = exercise.logs, !logs.isEmpty else { return nil }
            
            let maxWeight = logs.map { $0.weight }.max() ?? 0
            let maxVolume = logs.map { $0.weight * Double($0.reps) * Double($0.sets) }.max() ?? 0
            let prLog = logs.filter { $0.weight == maxWeight }.max(by: { $0.date < $1.date })
            
            return (
                exercise: exercise,
                maxWeight: maxWeight,
                maxVolume: maxVolume,
                prDate: prLog?.date
            )
        }
        .sorted { $0.maxWeight > $1.maxWeight }
    }
    
    var body: some View {
        List {
            // Category filter
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            color: .gray
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                color: categoryColor(category)
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            // PRs list
            if exercisesWithPRs.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Personal Records Yet")
                            .font(.headline)
                        
                        Text("Complete workouts to track your personal bests here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                }
            } else {
                Section("Personal Records") {
                    ForEach(exercisesWithPRs, id: \.exercise.id) { item in
                        NavigationLink {
                            ExerciseProgressView(exercise: item.exercise)
                        } label: {
                            PRRow(
                                exercise: item.exercise,
                                maxWeight: item.maxWeight,
                                prDate: item.prDate
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Personal Records")
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

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.15))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PRRow: View {
    let exercise: Exercise
    let maxWeight: Double
    let prDate: Date?
    
    var body: some View {
        HStack(spacing: 12) {
            // Category indicator
            Circle()
                .fill(categoryColor)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                if let date = prDate {
                    Text("Achieved \(date, format: .dateTime.month().day().year())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", maxWeight))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                Text("lbs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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

#Preview {
    NavigationStack {
        PersonalRecordsView()
    }
}
