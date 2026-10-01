import Foundation
import DeviceActivity

final class ScreenTimeMonitor {
    static let shared = ScreenTimeMonitor()

    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("timeup.daily")

    private init() {}

    func startMonitoring(targetMinutes: Int) throws {
        let safeTarget = max(1, targetMinutes)

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let targetEventName = DeviceActivityEvent.Name(
            "timeup.target.\(safeTarget)"
        )

        let targetEvent = DeviceActivityEvent(
            threshold: DateComponents(minute: safeTarget),
            includesPastActivity: true
        )

        try center.startMonitoring(
            activityName,
            during: schedule,
            events: [targetEventName: targetEvent]
        )
    }

    func startPrototypeMonitoring() throws {
        try startMonitoring(targetMinutes: 5)
    }

    func stopMonitoring() {
        center.stopMonitoring([activityName])
    }
}
