//
//  NotificationManager.swift
//  Coughy
//
//  Created by Brian Chang on 19/08/26.
//


import UserNotifications

enum NotificationManager {
    static func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func notifyReportReady() {
        let content = UNMutableNotificationContent()
        content.title = "Cough Detected"
        content.body  = "Tap to view last night's report."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "report-ready-\(UUID().uuidString)",
            content: content,
            trigger: nil          // kirim langsung
        )
        UNUserNotificationCenter.current().add(request)
    }
}

// Supaya notifikasi tetap muncul walau app sedang di depan
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}