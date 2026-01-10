//
//  TimerLockScreenLiveActivity.swift
//  TimerLockScreen
//
//  Created by Mohamed Atef on 25/12/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Use the live_activities package attributes format
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable { }

    var id = UUID()
}

struct TimerLockScreenLiveActivity: Widget {

    // Access shared UserDefaults for data from Flutter
    let sharedDefault = UserDefaults(suiteName: "group.com.mindfree.app")

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            // Lock screen/banner UI
            let timerName = sharedDefault?.string(forKey: context.attributes.prefixedKey("timerName")) ?? "Focus Timer"
            let remainingSeconds = sharedDefault?.integer(forKey: context.attributes.prefixedKey("remainingSeconds")) ?? 0
            let totalSeconds = sharedDefault?.integer(forKey: context.attributes.prefixedKey("totalSeconds")) ?? 1500
            let isRunning = sharedDefault?.bool(forKey: context.attributes.prefixedKey("isRunning")) ?? false

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                        Text(timerName)
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Text(isRunning ? "Focus in progress" : "Timer paused")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(formatTime(remainingSeconds))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    ProgressView(
                        value: Double(totalSeconds - remainingSeconds),
                        total: Double(max(totalSeconds, 1))
                    )
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .frame(width: 100)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            let timerName = sharedDefault?.string(forKey: context.attributes.prefixedKey("timerName")) ?? "Timer"
            let remainingSeconds = sharedDefault?.integer(forKey: context.attributes.prefixedKey("remainingSeconds")) ?? 0
            let totalSeconds = sharedDefault?.integer(forKey: context.attributes.prefixedKey("totalSeconds")) ?? 1500
            let isRunning = sharedDefault?.bool(forKey: context.attributes.prefixedKey("isRunning")) ?? false

            return DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                        Text(timerName)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(isRunning ? "Running" : "Paused")
                        .font(.caption2)
                        .foregroundColor(isRunning ? .green : .orange)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(formatTime(remainingSeconds))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(
                        value: Double(totalSeconds - remainingSeconds),
                        total: Double(max(totalSeconds, 1))
                    )
                    .progressViewStyle(.linear)
                    .tint(.blue)
                }
            } compactLeading: {
                // Compact leading (left pill)
                Image(systemName: isRunning ? "timer" : "pause.circle")
                    .foregroundColor(.blue)
            } compactTrailing: {
                // Compact trailing (right pill)
                Text(formatTimeCompact(remainingSeconds))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            } minimal: {
                // Minimal view
                Image(systemName: "timer")
                    .foregroundColor(.blue)
            }
            .keylineTint(.blue)
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func formatTimeCompact(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

#Preview("Notification", as: .content, using: LiveActivitiesAppAttributes()) {
   TimerLockScreenLiveActivity()
} contentStates: {
    LiveActivitiesAppAttributes.ContentState()
}
