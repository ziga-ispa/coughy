//
//  MonitoringCoordinator.swift
//  CoughyPhone
//
//  Created by Brian Chang on 19/08/26.
//


import AppIntents
import Foundation

final class MonitoringCoordinator {
    static let shared = MonitoringCoordinator()
    private init() {}
    var stopHandler: (@MainActor () -> Void)?
}

struct StopMonitoringIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Monitoring"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            MonitoringCoordinator.shared.stopHandler?()
        }
        return .result()
    }
}
