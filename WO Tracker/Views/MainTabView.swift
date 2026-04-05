//
//  MainTabView.swift
//  WO Tracker
//
//  Main tab navigation for the app
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            WorkoutsTabView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }
            
            PlansTabView()
                .tabItem {
                    Label("Plans", systemImage: "list.bullet.clipboard")
                }
            
            ExercisesTabView()
                .tabItem {
                    Label("Exercises", systemImage: "dumbbell")
                }
            
            StatsTabView()
                .tabItem {
                    Label("Stats", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(.orange)
    }
}

#Preview {
    MainTabView()
}
