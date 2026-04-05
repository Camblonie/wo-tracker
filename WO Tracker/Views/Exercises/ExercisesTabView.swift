//
//  ExercisesTabView.swift
//  WO Tracker
//
//  Container view for the exercises tab
//

import SwiftUI

struct ExercisesTabView: View {
    var body: some View {
        NavigationStack {
            ExerciseLibraryView()
        }
    }
}

#Preview {
    ExercisesTabView()
}
