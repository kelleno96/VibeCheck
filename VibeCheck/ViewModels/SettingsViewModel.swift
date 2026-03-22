import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    var notificationTime: Date {
        didSet {
            let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
            let hour = components.hour ?? 20
            let minute = components.minute ?? 0
            UserDefaults.standard.set(hour, forKey: "notificationHour")
            UserDefaults.standard.set(minute, forKey: "notificationMinute")
            NotificationManager.shared.scheduleDailyNotification(hour: hour, minute: minute)
        }
    }

    init() {
        let hour = UserDefaults.standard.object(forKey: "notificationHour") as? Int ?? 20
        let minute = UserDefaults.standard.object(forKey: "notificationMinute") as? Int ?? 0
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        self.notificationTime = Calendar.current.date(from: components) ?? Date()
    }
}
