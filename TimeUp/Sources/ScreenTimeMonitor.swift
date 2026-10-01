import Foundation
import DeviceActivity

final class ScreenTimeMonitor {
    static let shared = ScreenTimeMonitor()

    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("timeup.daily")
    private let sharedDefaults = UserDefaults(
        suiteName: "group.com.timeup.shared"
    )

    private init() {}

    func startMonitoring(targetMinutes: Int? = nil) throws {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        for minutes in stride(from: 5, through: 24 * 60, by: 5) {
            let eventName = DeviceActivityEvent.Name(
                "timeup.usage.\(minutes)"
            )

            events[eventName] = DeviceActivityEvent(
                threshold: DateComponents(minute: minutes),
                includesPastActivity: true
            )
        }

        if let targetMinutes {
            sharedDefaults?.set(
                max(1, targetMinutes),
                forKey: "configuredDailyTargetMinutes"
            )
        } else {
            sharedDefaults?.removeObject(
                forKey: "configuredDailyTargetMinutes"
            )
        }

        try center.startMonitoring(
            activityName,
            during: schedule,
            events: events
        )
    }

    func startPrototypeMonitoring() throws {
        try startMonitoring()
    }

    func stopMonitoring() {
        center.stopMonitoring([activityName])
    }
}
