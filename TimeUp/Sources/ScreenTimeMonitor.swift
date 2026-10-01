import Foundation
import DeviceActivity

final class ScreenTimeMonitor {
    static let shared = ScreenTimeMonitor()

    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("timeup.daily")

    private init() {}

    func startMonitoring() throws {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
            DeviceActivityEvent.Name("timeup.5min"): DeviceActivityEvent(
                threshold: DateComponents(minute: 5),
                includesPastActivity: true
            )
        ]

        try center.startMonitoring(
            activityName,
            during: schedule,
            events: events
        )
    }

    func stopMonitoring() {
        center.stopMonitoring([activityName])
    }
}
