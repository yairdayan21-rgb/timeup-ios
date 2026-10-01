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

        print("TimeUp monitoring interval started: \(activity.rawValue)")
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        sharedDefaults?.set(
            Date(),
            forKey: "lastThresholdReachedAt"
        )

        sharedDefaults?.set(
            event.rawValue,
            forKey: "lastThresholdEventName"
        )

        print("TimeUp threshold reached: \(event.rawValue)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        sharedDefaults?.set(
            Date(),
            forKey: "monitoringIntervalEndedAt"
        )

        print("TimeUp monitoring interval ended: \(activity.rawValue)")
    }
}
