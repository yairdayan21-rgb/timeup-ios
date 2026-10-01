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

        let normalizedTarget = targetMinutes.map { max(1, $0) }
        var thresholds = Set<Int>()

        // Normal precision: one checkpoint every 10 minutes.
        for minutes in stride(from: 10, through: 24 * 60, by: 10) {
            thresholds.insert(minutes)
        }

        if let target = normalizedTarget {
            // Higher precision as the member approaches the daily target:
            // every 2 minutes during the final 10 minutes, then every minute
            // during the final 5 minutes.
            for minutes in stride(from: max(1, target - 10), through: target, by: 2) {
                thresholds.insert(minutes)
            }

            for minutes in max(1, target - 5)...target {
                thresholds.insert(minutes)
            }
        }

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        for minutes in thresholds.sorted() {
            let eventName = DeviceActivityEvent.Name(
                "timeup.usage.\(minutes)"
            )

            events[eventName] = DeviceActivityEvent(
                threshold: DateComponents(minute: minutes),
                includesPastActivity: true
            )
        }

        if let normalizedTarget {
            sharedDefaults?.set(
                normalizedTarget,
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
