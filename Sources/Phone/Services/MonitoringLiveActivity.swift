//
//  MonitoringLiveActivity.swift
//  Coughy
//
//  Created by Brian Chang on 19/08/26.
//


import ActivityKit
import Foundation

final class MonitoringLiveActivity {
    private var activity: Activity<MonitoringActivityAttributes>?

    func start(startDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end() // jaga-jaga kalau ada sisa

        let attributes = MonitoringActivityAttributes(title: "Nighttime Monitoring Active")
        let state = MonitoringActivityAttributes.ContentState(startDate: startDate, coughCount: 0)
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil          // lokal, tidak butuh server push
            )
        } catch {
            print("Live Activity start error: \(error)")
        }
    }

    func update(startDate: Date, coughCount: Int) {
        guard let activity else { return }
        let state = MonitoringActivityAttributes.ContentState(startDate: startDate, coughCount: coughCount)
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}