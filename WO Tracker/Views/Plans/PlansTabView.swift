//
//  PlansTabView.swift
//  WO Tracker
//
//  Container view for the plans tab
//

import SwiftUI
import SwiftData

struct PlansTabView: View {
    var body: some View {
        NavigationStack {
            PlanListView()
        }
    }
}

#Preview {
    PlansTabView()
        .modelContainer(for: WorkoutPlan.self, inMemory: true)
}
