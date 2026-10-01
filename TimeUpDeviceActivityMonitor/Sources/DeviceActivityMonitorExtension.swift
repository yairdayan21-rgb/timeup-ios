import Foundation
import DeviceActivity
import UserNotifications

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

        sharedDefaults?.set(0, forKey: "estimatedUsageMinutes")
        sharedDefaults?.removeObject(forKey: "dailyTargetReachedAt")
        sharedDefaults?.removeObject(forKey: "dailyTargetMinutes")
        sharedDefaults?.removeObject(forKey: "dailyTargetWarningSentAt")
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

        guard let usageMinutes = usageMinutes(from: event) else {
            return
        }

        let previousEstimate = sharedDefaults?.integer(
            forKey: "estimatedUsageMinutes"
        ) ?? 0

        let newEstimate = max(previousEstimate, usageMinutes)
        sharedDefaults?.set(
            newEstimate,
            forKey: "estimatedUsageMinutes"
        )

        let configuredTarget = sharedDefaults?.integer(
            forKey: "configuredDailyTargetMinutes"
        ) ?? 0

        guard configuredTarget > 0 else { return }

        let minutesRemaining = configuredTarget - newEstimate

        // Warn once per day when the member enters the final five minutes.
        if minutesRemaining > 0,
           minutesRemaining <= 5,
           sharedDefaults?.object(forKey: "dailyTargetWarningSentAt") == nil {
            sendTargetWarning(minutesRemaining: minutesRemaining)
            sharedDefaults?.set(now, forKey: "dailyTargetWarningSentAt")
        }

        if newEstimate >= configuredTarget,
           sharedDefaults?.object(forKey: "dailyTargetReachedAt") == nil {
            sharedDefaults?.set(now, forKey: "dailyTargetReachedAt")
            sharedDefaults?.set(
                configuredTarget,
                forKey: "dailyTargetMinutes"
            )
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        let now = Date()
        let usageMinutes = sharedDefaults?.integer(
            forKey: "estimatedUsageMinutes"
        ) ?? 0

        sharedDefaults?.set(
            now,
            forKey: "monitoringIntervalEndedAt"
        )
        sharedDefaults?.set(
            usageMinutes,
            forKey: "lastCompletedDayUsageMinutes"
        )
        sharedDefaults?.set(
            now,
            forKey: "lastCompletedDayDate"
        )
    }

    private func sendTargetWarning(minutesRemaining: Int) {
        let content = UNMutableNotificationContent()
        content.title = "TimeUp"
        content.body = minutesRemaining == 1
            ? "נשארה לך בערך דקה אחת עד ליעד היומי."
            : "נשארו לך בערך \(minutesRemaining) דקות עד ליעד היומי."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "timeup.daily-target-warning",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func usageMinutes(
        from event: DeviceActivityEvent.Name
    ) -> Int? {
        let prefix = "timeup.usage."

        guard event.rawValue.hasPrefix(prefix) else {
            return nil
        }

        return Int(event.rawValue.dropFirst(prefix.count))
    }
}
