import Foundation
import DeviceActivity

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let sharedDefaults = UserDefaults(
        suiteName: "group.com.timeup.shared"
    )

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        sharedDefaults?.set(
            Date(),
            forKey: "monitoringIntervalStartedAt"
        )

        sharedDefaults?.removeObject(forKey: "dailyTargetReachedAt")
        sharedDefaults?.removeObject(forKey: "dailyTargetMinutes")
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        let now = Date()
        sharedDefaults?.set(now, forKey: "lastThresholdReachedAt")
        sharedDefaults?.set(
            event.rawValue,
            forKey: "lastThresholdEventName"
        )

        if let targetMinutes = targetMinutes(from: event) {
            sharedDefaults?.set(now, forKey: "dailyTargetReachedAt")
            sharedDefaults?.set(
                targetMinutes,
                forKey: "dailyTargetMinutes"
            )
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        sharedDefaults?.set(
            Date(),
            forKey: "monitoringIntervalEndedAt"
        )
    }

    private func targetMinutes(
        from event: DeviceActivityEvent.Name
    ) -> Int? {
        let prefix = "timeup.target."

        guard event.rawValue.hasPrefix(prefix) else {
            return nil
        }

        return Int(event.rawValue.dropFirst(prefix.count))
    }
}
