import DeviceActivity
import SwiftUI

@main
struct TimeUpDeviceActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TimeUpDailyActivityReport { totalActivityDuration in
            TimeUpDailyActivityView(
                totalActivityDuration: totalActivityDuration
            )
        }
    }
}

struct TimeUpDailyActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context =
        .init("timeup.daily.total")

    let content: (TimeInterval) -> TimeUpDailyActivityView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> TimeInterval {
        var totalActivityDuration: TimeInterval = 0

        for await deviceData in data {
            for await segment in deviceData.activitySegments {
                totalActivityDuration += segment.totalActivityDuration
            }
        }

        let totalMinutes = max(
            0,
            Int(totalActivityDuration / 60)
        )

        let defaults = UserDefaults(
            suiteName: "group.com.timeup.shared"
        )

        defaults?.set(
            totalMinutes,
            forKey: "reportedUsageMinutes"
        )

        defaults?.set(
            Date(),
            forKey: "reportedUsageUpdatedAt"
        )

        return totalActivityDuration
    }
}

struct TimeUpDailyActivityView: View {
    let totalActivityDuration: TimeInterval

    private var totalMinutes: Int {
        max(
            0,
            Int(totalActivityDuration / 60)
        )
    }

    var body: some View {
        Text("\(totalMinutes)")
            .font(.system(size: 1))
            .foregroundStyle(.clear)
            .accessibilityHidden(true)
    }
}
