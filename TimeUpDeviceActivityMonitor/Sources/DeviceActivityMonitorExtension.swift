import Foundation
import DeviceActivity
import UserNotifications

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let sharedDefaults = UserDefaults(
        suiteName: "group.com.timeup.shared"
    )

    private let calendar = Calendar.current

    // MARK: - Interval Start

    override func intervalDidStart(
        for activity: DeviceActivityName
    ) {
        super.intervalDidStart(
            for: activity
        )

        let now = Date()

        let dayStart =
            calendar.startOfDay(
                for: now
            )

        sharedDefaults?.set(
            now,
            forKey: "monitoringIntervalStartedAt"
        )

        // שומרים במפורש לאיזה יום
        // שייכים נתוני ה-Screen Time.
        sharedDefaults?.set(
            dayStart,
            forKey: "monitoringDayDate"
        )

        // איפוס ההערכה בתחילת יום חדש.
        sharedDefaults?.set(
            0,
            forKey: "estimatedUsageMinutes"
        )

        // גם ה-snapshot שמיועד לסנכרון
        // מתחיל מאפס ביום החדש.
        sharedDefaults?.set(
            0,
            forKey: "reportedUsageMinutes"
        )

        sharedDefaults?.set(
            now,
            forKey: "reportedUsageUpdatedAt"
        )

        sharedDefaults?.removeObject(
            forKey: "dailyTargetReachedAt"
        )

        sharedDefaults?.removeObject(
            forKey: "dailyTargetMinutes"
        )

        sharedDefaults?.removeObject(
            forKey: "dailyTargetWarningSentAt"
        )
    }

    // MARK: - Usage Threshold

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(
            event,
            activity: activity
        )

        let now = Date()

        sharedDefaults?.set(
            now,
            forKey: "lastThresholdReachedAt"
        )

        sharedDefaults?.set(
            event.rawValue,
            forKey: "lastThresholdEventName"
        )

        guard let usageMinutes =
            usageMinutes(
                from: event
            )
        else {
            return
        }

        let previousEstimate =
            sharedDefaults?.integer(
                forKey: "estimatedUsageMinutes"
            ) ?? 0

        let newEstimate =
            max(
                previousEstimate,
                usageMinutes
            )

        // MARK: Local Screen Time Snapshot

        sharedDefaults?.set(
            newEstimate,
            forKey: "estimatedUsageMinutes"
        )

        // MARK: Supabase Sync Snapshot
        //
        // SupabaseDataStore קורא את שני
        // המפתחות האלה ומעלה אותם ל-daily_results.
        //
        // לכן בכל threshold של DeviceActivity
        // נוצר snapshot חדש שמוכן לסנכרון.

        sharedDefaults?.set(
            newEstimate,
            forKey: "reportedUsageMinutes"
        )

        sharedDefaults?.set(
            now,
            forKey: "reportedUsageUpdatedAt"
        )

        // שומרים גם את היום שאליו
        // שייך ה-snapshot.
        let monitoringDay =
            sharedDefaults?.object(
                forKey: "monitoringDayDate"
            ) as? Date
            ?? calendar.startOfDay(
                for: now
            )

        sharedDefaults?.set(
            monitoringDay,
            forKey: "reportedUsageDayDate"
        )

        // MARK: Target

        let configuredTarget =
            sharedDefaults?.integer(
                forKey:
                    "configuredDailyTargetMinutes"
            ) ?? 0

        guard configuredTarget > 0 else {
            return
        }

        let minutesRemaining =
            configuredTarget -
            newEstimate

        // MARK: Target Warning

        if minutesRemaining > 0,
           minutesRemaining <= 5,
           sharedDefaults?.object(
                forKey:
                    "dailyTargetWarningSentAt"
           ) == nil {

            sendTargetWarning(
                minutesRemaining:
                    minutesRemaining
            )

            sharedDefaults?.set(
                now,
                forKey:
                    "dailyTargetWarningSentAt"
            )
        }

        // MARK: Target Reached

        if newEstimate >= configuredTarget,
           sharedDefaults?.object(
                forKey:
                    "dailyTargetReachedAt"
           ) == nil {

            sharedDefaults?.set(
                now,
                forKey:
                    "dailyTargetReachedAt"
            )

            sharedDefaults?.set(
                configuredTarget,
                forKey:
                    "dailyTargetMinutes"
            )
        }
    }

    // MARK: - Interval End

    override func intervalDidEnd(
        for activity: DeviceActivityName
    ) {
        super.intervalDidEnd(
            for: activity
        )

        let now = Date()

        let usageMinutes =
            sharedDefaults?.integer(
                forKey: "estimatedUsageMinutes"
            ) ?? 0

        // משתמשים ביום שנשמר בתחילת
        // חלון המדידה ולא בתאריך סיום משוער.
        let completedDay =
            sharedDefaults?.object(
                forKey: "monitoringDayDate"
            ) as? Date
            ?? calendar.startOfDay(
                for: now
            )

        sharedDefaults?.set(
            now,
            forKey: "monitoringIntervalEndedAt"
        )

        sharedDefaults?.set(
            usageMinutes,
            forKey:
                "lastCompletedDayUsageMinutes"
        )

        sharedDefaults?.set(
            completedDay,
            forKey:
                "lastCompletedDayDate"
        )

        // שומרים snapshot סופי נוסף
        // עבור היום שהסתיים.
        sharedDefaults?.set(
            usageMinutes,
            forKey: "reportedUsageMinutes"
        )

        sharedDefaults?.set(
            now,
            forKey: "reportedUsageUpdatedAt"
        )

        sharedDefaults?.set(
            completedDay,
            forKey: "reportedUsageDayDate"
        )
    }

    // MARK: - Notifications

    private func sendTargetWarning(
        minutesRemaining: Int
    ) {

        let content =
            UNMutableNotificationContent()

        content.title =
            "TimeUp"

        content.body =
            minutesRemaining == 1
            ? "נשארה לך בערך דקה אחת עד ליעד היומי."
            : "נשארו לך בערך \(minutesRemaining) דקות עד ליעד היומי."

        content.sound =
            .default

        let request =
            UNNotificationRequest(
                identifier:
                    "timeup.daily-target-warning",
                content: content,
                trigger: nil
            )

        UNUserNotificationCenter
            .current()
            .add(request)
    }

    // MARK: - Usage Event Parsing

    private func usageMinutes(
        from event:
            DeviceActivityEvent.Name
    ) -> Int? {

        let prefix =
            "timeup.usage."

        guard event.rawValue
            .hasPrefix(prefix)
        else {
            return nil
        }

        return Int(
            event.rawValue
                .dropFirst(
                    prefix.count
                )
        )
    }
}
