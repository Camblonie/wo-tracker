//
//  RestTimerView.swift
//  WO Tracker
//
//  Rest timer for between sets
//

import SwiftUI

struct RestTimerView: View {
    @Binding var isPresented: Bool
    @State private var timeRemaining: Int
    @State private var initialTime: Int
    @State private var timer: Timer?
    @State private var isRunning = false
    
    let onComplete: () -> Void
    
    init(isPresented: Binding<Bool>, initialSeconds: Int = 60, onComplete: @escaping () -> Void = {}) {
        self._isPresented = isPresented
        self._timeRemaining = State(initialValue: initialSeconds)
        self._initialTime = State(initialValue: initialSeconds)
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Timer display
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 250, height: 250)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: [.orange, .red],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)
                    
                    // Time text
                    VStack(spacing: 8) {
                        Text(formattedTime)
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        
                        Text(isRunning ? "Resting..." : "Paused")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Quick time presets
                HStack(spacing: 12) {
                    TimePresetButton(seconds: 30, currentTime: $timeRemaining) {
                        resetTimer(to: 30)
                    }
                    TimePresetButton(seconds: 60, currentTime: $timeRemaining) {
                        resetTimer(to: 60)
                    }
                    TimePresetButton(seconds: 90, currentTime: $timeRemaining) {
                        resetTimer(to: 90)
                    }
                    TimePresetButton(seconds: 120, currentTime: $timeRemaining) {
                        resetTimer(to: 120)
                    }
                }
                .padding(.horizontal)
                
                // Control buttons
                HStack(spacing: 20) {
                    Button {
                        if isRunning {
                            pauseTimer()
                        } else {
                            startTimer()
                        }
                    } label: {
                        Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.orange)
                    }
                    
                    Button {
                        resetTimer(to: initialTime)
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Done button
                Button {
                    stopTimer()
                    onComplete()
                    isPresented = false
                } label: {
                    Text("Skip Rest")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 40)
            .navigationTitle("Rest Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        stopTimer()
                        isPresented = false
                    }
                }
            }
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    private var progress: CGFloat {
        CGFloat(timeRemaining) / CGFloat(initialTime)
    }
    
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startTimer() {
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                onComplete()
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer(to seconds: Int) {
        stopTimer()
        timeRemaining = seconds
        initialTime = seconds
        startTimer()
    }
}

struct TimePresetButton: View {
    let seconds: Int
    @Binding var currentTime: Int
    let action: () -> Void
    
    var isSelected: Bool {
        currentTime == seconds
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Text("\(seconds)s")
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.systemGray5))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RestTimerView(isPresented: .constant(true))
}
