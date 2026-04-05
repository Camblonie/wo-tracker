//
//  ExerciseLibraryView.swift
//  WO Tracker
//
//  Main view for browsing and managing exercises
//

import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    @State private var selectedCategory: ExerciseCategory?
    @State private var searchText = ""
    @State private var showingAddExercise = false
    
    // Filter exercises based on search and category
    var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty || 
                exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || 
                exercise.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    // Group exercises by category for the list
    var exercisesByCategory: [(ExerciseCategory, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { $0.category }
        return grouped.sorted { $0.key.rawValue < $1.key.rawValue }
    }
    
    var body: some View {
        List {
            // Category filter section
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // All button
                        CategoryFilterButton(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            color: .gray
                        ) {
                            selectedCategory = nil
                        }
                        
                        // Category buttons
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            CategoryFilterButton(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                color: categoryColor(category)
                            ) {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            // Exercise list
            if selectedCategory == nil {
                // Show grouped by category when "All" is selected
                ForEach(exercisesByCategory, id: \.0) { category, categoryExercises in
                    Section {
                        ForEach(categoryExercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ExerciseRow(exercise: exercise)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                        }
                        .font(.headline)
                        .foregroundColor(categoryColor(category))
                    }
                }
            } else {
                // Show flat list when category is selected
                Section {
                    ForEach(filteredExercises) { exercise in
                        NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                            ExerciseRow(exercise: exercise)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Exercises")
        .searchable(text: $searchText, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView()
        }
    }
    
    // Helper function to get color for category
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

// MARK: - Supporting Views

struct CategoryFilterButton: View {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.15))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    
    var body: some View {
        HStack {
            // Category indicator
            Circle()
                .fill(categoryColor(exercise.category))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                if !exercise.muscleGroups.isEmpty {
                    Text(exercise.muscleGroups)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if !exercise.isBuiltIn {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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
    ExerciseLibraryView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
