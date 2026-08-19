//
//  MonitoringActivityAttributes.swift
//  CoughyPhone
//
//  Created by Brian Chang on 19/08/26.
//


import ActivityKit
import Foundation

struct MonitoringActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startDate: Date
        var coughCount: Int
    }
    var title: String
}
