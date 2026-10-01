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

        try center.startMonitoring(
            activityName,
            during: schedule
        )
    }

    func stopMonitoring() {
        center.stopMonitoring([activityName])
    }
}
