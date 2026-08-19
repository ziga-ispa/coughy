//
//  CoughyWidgetBundle.swift
//  CoughyPhone
//
//  Created by Brian Chang on 19/08/26.
//


import WidgetKit
import SwiftUI

@main
struct CoughyWidgetBundle: WidgetBundle {
    var body: some Widget {
        CoughyMonitoringLiveActivity()
    }
}