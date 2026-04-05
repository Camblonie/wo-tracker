//
//  DataExportView.swift
//  WO Tracker
//
//  View for exporting workout data
//

import SwiftUI
import SwiftData

struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Export Data") {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Export Your Workout Data")
                            .font(.headline)
                        
                        Text("Create a JSON file containing all your workout history, plans, and exercise data. You can share this file for backup or import it to another device.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            exportData()
                        } label: {
                            HStack {
                                if isExporting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.down.doc")
                                }
                                Text(isExporting ? "Exporting..." : "Export to JSON")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .disabled(isExporting)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 20)
                }
                
                Section("Data Summary") {
                    StatRow(title: "Total Workouts", value: "\(sessions.filter { $0.status == .completed }.count)")
                    StatRow(title: "Exercises", value: "\(exercises.count)")
                    StatRow(title: "Workout Plans", value: "\(exercises.compactMap { $0.logs }.count)")
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                } footer: {
                    Text("This will permanently delete all your workout history, plans, and custom exercises. Built-in exercises will remain.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Data Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet, onDismiss: {
                // Clean up temporary file
                if let url = exportURL {
                    try? FileManager.default.removeItem(at: url)
                }
            }) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This action cannot be undone. All your workout history will be permanently deleted.")
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let exportData = createExportData()
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("WOTracker_Export_\(Date().timeIntervalSince1970).json")
                
                try jsonData.write(to: tempURL)
                
                DispatchQueue.main.async {
                    exportURL = tempURL
                    isExporting = false
                    showShareSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    isExporting = false
                }
            }
        }
    }
    
    private func createExportData() -> [String: Any] {
        let dateFormatter = ISO8601DateFormatter()
        
        // Export sessions
        let sessionsData: [[String: Any]] = sessions.compactMap { session in
            guard session.status == .completed else { return nil }
            
            return [
                "id": session.id.uuidString,
                "startedAt": dateFormatter.string(from: session.startedAt),
                "completedAt": session.completedAt.map { dateFormatter.string(from: $0) } ?? NSNull(),
                "planName": session.plan?.name ?? NSNull(),
                "notes": session.notes ?? NSNull()
            ]
        }
        
        // Export logs
        let logsData: [[String: Any]] = allLogs.map { log in
            [
                "exerciseName": log.exercise?.name ?? "Unknown",
                "date": dateFormatter.string(from: log.date),
                "weight": log.weight,
                "reps": log.reps,
                "sets": log.sets,
                "notes": log.notes ?? NSNull()
            ]
        }
        
        return [
            "exportDate": dateFormatter.string(from: Date()),
            "appVersion": "1.0",
            "sessions": sessionsData,
            "workoutLogs": logsData
        ]
    }
    
    private var allLogs: [WorkoutLog] {
        // Fetch all logs through exercises
        exercises.flatMap { $0.logs ?? [] }
    }
    
    private func deleteAllData() {
        // Delete all sessions
        for session in sessions {
            modelContext.delete(session)
        }
        
        // Delete custom exercises
        for exercise in exercises where !exercise.isBuiltIn {
            modelContext.delete(exercise)
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DataExportView()
}
