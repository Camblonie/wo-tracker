//
//  PlanListView.swift
//  WO Tracker
//
//  View for displaying all workout plans
//

import SwiftUI
import SwiftData

struct PlanListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    
    @State private var showingAddPlan = false
    @State private var planToEdit: WorkoutPlan?
    
    var body: some View {
        List {
            if plans.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Workout Plans Yet")
                            .font(.headline)
                        
                        Text("Create your first workout plan to get started.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            showingAddPlan = true
                        } label: {
                            Text("Create Plan")
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                            .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(plans) { plan in
                    NavigationLink(value: plan) {
                        PlanRow(plan: plan)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deletePlan(plan)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            planToEdit = plan
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.indigo)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Workout Plans")
        .navigationDestination(for: WorkoutPlan.self) { plan in
            PlanDetailView(plan: plan)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddPlan = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPlan) {
            PlanEditorView()
        }
        .sheet(item: $planToEdit) { plan in
            PlanEditorView(plan: plan)
        }
    }
    
    private func deletePlan(_ plan: WorkoutPlan) {
        modelContext.delete(plan)
    }
}

// MARK: - Supporting Views

struct PlanRow: View {
    let plan: WorkoutPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(plan.name)
                    .font(.headline)
                
                Spacer()
                
                if let duration = plan.estimatedDuration {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(duration)m")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            if let details = plan.details, !details.isEmpty {
                Text(details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 12) {
                // Exercise count
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell")
                        .font(.caption)
                    Text("\(plan.movements?.count ?? 0) exercises")
                        .font(.caption)
                }
                .foregroundColor(.blue)
                
                // Last performed
                if let lastPerformed = plan.lastPerformed {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(lastPerformed, format: .dateTime.month().day())
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PlanListView()
    }
    .modelContainer(for: WorkoutPlan.self, inMemory: true)
}
