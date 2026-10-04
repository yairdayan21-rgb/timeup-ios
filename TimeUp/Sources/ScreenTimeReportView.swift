import SwiftUI
import DeviceActivity

struct ScreenTimeReportView: View {

    private let context =
        DeviceActivityReport.Context(
            "timeup.daily.total"
        )

    private var todayFilter: DeviceActivityFilter {

        let calendar = Calendar.current
        let now = Date()

        let startOfDay =
            calendar.startOfDay(for: now)

        let interval = DateInterval(
            start: startOfDay,
            end: now
        )

        return DeviceActivityFilter(
            segment: .daily(
                during: interval
            ),
            users: .all,
            devices: .all
        )
    }

    var body: some View {
        DeviceActivityReport(
            context,
            filter: todayFilter
        )
        .frame(width: 1, height: 1)
        .opacity(0.01)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
