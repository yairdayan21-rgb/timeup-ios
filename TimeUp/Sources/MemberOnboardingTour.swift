import SwiftUI

// MARK: - Member Onboarding Tour

struct MemberOnboardingTour: View {

    enum Mode {
        case firstTime
        case replay
    }

    let mode: Mode
    let goalMethod: String
    let onSelectTab: (TourDestination) -> Void
    let onFinish: () async -> Void

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var stepIndex = 0
    @State private var isFinishing = false

    enum TourDestination {
        case dashboard
        case group
        case ranking
    }

    private var steps: [TourStep] {

        [
            TourStep(
                destination: .dashboard,
                icon: "target",
                title: targetTitle,
                message: targetMessage
            ),

            TourStep(
                destination: .dashboard,
                icon: "chart.bar.fill",
                title: progressTitle,
                message: progressMessage
            ),

            TourStep(
                destination: .group,
                icon: "person.3.fill",
                title: groupTitle,
                message: groupMessage
            ),

            TourStep(
                destination: .group,
                icon: "flame.fill",
                title: streakTitle,
                message: streakMessage
            ),

            TourStep(
                destination: .dashboard,
                icon: "figure.walk",
                title: alternativesTitle,
                message: alternativesMessage
            ),

            TourStep(
                destination: .group,
                icon: "bubble.left.and.bubble.right.fill",
                title: chatTitle,
                message: chatMessage
            ),

            TourStep(
                destination: .ranking,
                icon: "trophy.fill",
                title: rankingTitle,
                message: rankingMessage
            ),

            TourStep(
                destination: .dashboard,
                icon: "checkmark.circle.fill",
                title: finishTitle,
                message: finishMessage
            )
        ]
    }

    private var currentStep: TourStep {

        steps[
            min(
                stepIndex,
                steps.count - 1
            )
        ]
    }

    private var isLastStep: Bool {

        stepIndex ==
            steps.count - 1
    }

    var body: some View {

        ZStack {

            Color.black
                .opacity(0.46)
                .ignoresSafeArea()

            VStack {

                Spacer()

                tourCard
                    .padding(
                        .horizontal,
                        18
                    )
                    .padding(
                        .bottom,
                        24
                    )
            }
        }
        .transition(
            .opacity
        )
        .onAppear {

            showCurrentDestination()
        }
        .onChange(
            of: stepIndex
        ) { _, _ in

            showCurrentDestination()
        }
        .environment(
            \.locale,
            localization.language.locale
        )
        .environment(
            \.layoutDirection,
            localization.language.layoutDirection
        )
    }

    // MARK: - Card

    private var tourCard: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            header

            HStack(
                alignment: .top,
                spacing: 14
            ) {

                ZStack {

                    Circle()
                        .fill(
                            Color.accentColor
                                .opacity(0.14)
                        )
                        .frame(
                            width: 52,
                            height: 52
                        )

                    Image(
                        systemName:
                            currentStep.icon
                    )
                    .font(
                        .system(
                            size: 23,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        Color.accentColor
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 7
                ) {

                    Text(
                        currentStep.title
                    )
                    .font(
                        .title3.bold()
                    )

                    Text(
                        currentStep.message
                    )
                    .font(
                        .body
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                Spacer(
                    minLength: 0
                )
            }

            progressDots

            controls
        }
        .padding(20)
        .background(
            .regularMaterial,
            in:
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
        )
        .shadow(
            radius: 18
        )
    }

    // MARK: - Header

    private var header: some View {

        HStack {

            Text(
                stepCounterText
            )
            .font(
                .caption
            )
            .fontWeight(
                .semibold
            )
            .foregroundStyle(
                .secondary
            )

            Spacer()

            if mode == .replay {

                Button(
                    skipText
                ) {

                    finishTour()
                }
                .font(
                    .subheadline
                )
                .disabled(
                    isFinishing
                )
            }
        }
    }

    // MARK: - Progress

    private var progressDots:
        some View {

        HStack(
            spacing: 6
        ) {

            ForEach(
                steps.indices,
                id: \.self
            ) { index in

                Capsule()
                    .fill(
                        index == stepIndex
                            ? Color.accentColor
                            : Color.secondary
                                .opacity(0.22)
                    )
                    .frame(
                        width:
                            index == stepIndex
                            ? 22
                            : 7,
                        height: 7
                    )
                    .animation(
                        .easeInOut(
                            duration: 0.2
                        ),
                        value: stepIndex
                    )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
    }

    // MARK: - Controls

    private var controls: some View {

        HStack(
            spacing: 12
        ) {

            if stepIndex > 0 {

                Button {

                    withAnimation {

                        stepIndex -= 1
                    }

                } label: {

                    Text(
                        backText
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(
                    .bordered
                )
                .disabled(
                    isFinishing
                )
            }

            Button {

                if isLastStep {

                    finishTour()

                } else {

                    withAnimation {

                        stepIndex += 1
                    }
                }

            } label: {

                HStack(
                    spacing: 8
                ) {

                    if isFinishing {

                        ProgressView()
                            .controlSize(
                                .small
                            )
                    }

                    Text(
                        isLastStep
                            ? finishButtonText
                            : nextText
                    )
                }
                .frame(
                    maxWidth: .infinity
                )
            }
            .buttonStyle(
                .borderedProminent
            )
            .disabled(
                isFinishing
            )
        }
    }

    // MARK: - Navigation

    private func showCurrentDestination() {

        onSelectTab(
            currentStep.destination
        )
    }

    // MARK: - Finish

    private func finishTour() {

        guard !isFinishing else {
            return
        }

        isFinishing = true

        Task {

            await onFinish()

            await MainActor.run {

                isFinishing = false
            }
        }
    }

    // MARK: - Goal Method

    private var normalizedGoalMethod:
        String {

        goalMethod
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .lowercased()
    }

    private var targetMessage:
        String {

        switch normalizedGoalMethod {

        case "previousday":

            switch localization.language {

            case .hebrew:

                return
                    "היעד שלך אישי ומתפתח לפי השימוש שלך. כאשר כל הקבוצה מצליחה, היעד הבא שלך מחושב מהשימוש האישי שלך בהתאם לאחוז ההפחתה שהגדיר מנהל הקבוצה."

            case .english:

                return
                    "Your target is personal and evolves with your usage. When the whole group succeeds, your next target is calculated from your own usage using the reduction percentage set by the group admin."

            case .arabic:

                return
                    "هدفك شخصي ويتطور وفق استخدامك. عندما تنجح المجموعة بأكملها، يتم حساب هدفك التالي من استخدامك الشخصي وفق نسبة التخفيض التي حددها مسؤول المجموعة."
            }

        case "adaptiveaverage":

            switch localization.language {

            case .hebrew:

                return
                    "הקבוצה מתקדמת יחד. כאשר כולם מצליחים, היעד הבא מחושב לפי ממוצע השימוש של הקבוצה ובהתאם לאחוז ההפחתה שהגדיר מנהל הקבוצה."

            case .english:

                return
                    "The group progresses together. When everyone succeeds, the next target is calculated from the group's average usage using the reduction percentage set by the group admin."

            case .arabic:

                return
                    "تتقدم المجموعة معًا. عندما ينجح الجميع، يتم حساب الهدف التالي وفق متوسط استخدام المجموعة ونسبة التخفيض التي حددها مسؤول المجموعة."
            }

        case "manual":

            switch localization.language {

            case .hebrew:

                return
                    "מנהל הקבוצה קובע עבורך יעד זמן אישי. היעד נשאר קבוע עד שמנהל הקבוצה משנה אותו."

            case .english:

                return
                    "The group admin sets your individual screen-time target. It remains fixed until the admin changes it."

            case .arabic:

                return
                    "يحدد مسؤول المجموعة هدف وقت الشاشة الخاص بك. يبقى الهدف ثابتًا حتى يقوم المسؤول بتغييره."
            }

        default:

            switch localization.language {

            case .hebrew:

                return
                    "כאן תראה את יעד זמן המסך שלך להיום ואת ההתקדמות שלך מולו."

            case .english:

                return
                    "Here you can see today's screen-time target and your progress toward it."

            case .arabic:

                return
                    "هنا يمكنك رؤية هدف وقت الشاشة لليوم ومدى تقدمك نحوه."
            }
        }
    }

    // MARK: - Localized Content

    private var targetTitle:
        String {

        switch localization.language {

        case .hebrew:
            return "היעד שלך"

        case .english:
            return "Your Target"

        case .arabic:
            return "هدفك"
        }
    }

    private var progressTitle:
        String {

        switch localization.language {

        case .hebrew:
            return "היום שלך"

        case .english:
            return "Your Day"

        case .arabic:
            return "يومك"
        }
    }

    private var progressMessage:
        String {

        switch localization.language {

        case .hebrew:

            return
                "בדשבורד תראה כמה זמן מסך צברת היום, מה היעד שלך ומה הסטטוס שלך מולו."

        case .english:

            return
                "The dashboard shows today's screen time, your target, and your current status against it."

        case .arabic:

            return
                "تعرض لوحة التحكم وقت الشاشة لليوم وهدفك وحالتك الحالية مقارنة به."
        }
    }

    private var groupTitle:
        String {

        switch localization.language {

        case .hebrew:
            return "אתם קבוצה"

        case .english:
            return "You're a Group"

        case .arabic:
            return "أنتم مجموعة"
        }
    }

    private var groupMessage:
        String {

        switch localization.language {

        case .hebrew:

            return
                "TimeUp הוא אתגר קבוצתי: הקבוצה עוזרת לך לעמוד ביעד — ואתה עוזר לקבוצה להצליח. במסך הקבוצה תוכל לראות את מצב החברים וההתקדמות המשותפת."

        case .english:

            return
                "TimeUp is a group challenge: the group helps you reach your target — and you help the group succeed. The Group screen shows everyone's status and shared progress."

        case .arabic:

            return
                "TimeUp هو تحدٍ جماعي: تساعدك المجموعة على تحقيق هدفك — وأنت تساعد المجموعة على النجاح. تعرض شاشة المجموعة حالة الأعضاء والتقدم المشترك."
        }
    }

    private var streakTitle:
        String {

        switch localization.language {

        case .hebrew:
            return "הרצף הקבוצתי"

        case .english:
            return "Group Streak"

        case .arabic:
            return "سلسلة نجاح المجموعة"
        }
    }

    private var streakMessage:
        String {

        switch localization.language {

        case .hebrew:

            return
                "הרצף מתקדם רק כאשר כל חברי הקבוצה עומדים ביעד. אם אחד לא מצליח, הרצף הקבוצתי מתאפס."

        case .english:

            return
                "The streak advances only when every group member meets the target. If one member misses it, the group streak resets."

        case .arabic:

            return
                "تتقدم السلسلة فقط عندما يحقق جميع أعضاء المجموعة الهدف. إذا لم ينجح أحد الأعضاء، تتم إعادة السلسلة الجماعية."
        }
    }

    private var alternativesTitle:
        String {

        switch localization.language {

        case .hebrew:
            return "מה עושים במקום מסך?"

        case .english:
            return "What Instead of Screen Time?"

        case .arabic:
            return "ماذا تفعل بدل وقت الشاشة؟"
        }
    }

    private var alternativesMessage:
        String {

        switch localization.language {

        case .hebrew:

            return
                "בכל יום תקבל הצעות לפעילויות בלי מסך. עשית פעילות? סמן אותה והיא תופיע בפעילות הקבוצתית ותוחלף בהצעה חדשה."

        case .english:

            return
                "Every day you'll get screen-free activity ideas. Complete one, mark it, and it will appear in the group activity feed while a new suggestion replaces it."

        case .arabic:

            return
                "ستحصل كل يوم على أفكار لأنشطة بدون شاشة. عند إكمال نشاط، قم بتحديده ليظهر في نشاط المجموعة ويتم استبداله باقتراح جديد."
        }
    }

    private var chatTitle:
        String {

        switch localization.language {

        case .hebrew:
            return "הצ׳אט של הקבוצה"

        case .english:
            return "Group Chat"

        case .arabic:
            return "دردشة المجموعة"
        }
    }

    private var chatMessage:
        String {

        switch localization.language {

        case .hebrew:

            return
                "דרך מסך הקבוצה תוכלו לעודד אחד את השני, לשתף ולהישאר מחוברים. הודעות חדשות שלא קראת יופיעו במונה הצ׳אט."

        case .english:

            return
                "Use the Group screen to encourage each other, share, and stay connected. Unread messages appear on the chat counter."

        case .arabic:

            return
                "استخدم شاشة المجموعة لتشجيع بعضكم البعض والمشاركة والبقاء على تواصل. تظهر الرسائل غير المقروءة في عداد الدردشة."
        }
    }

    private var rankingTitle:
        String {

        switch localization.language {

        case .hebrew:
            return "הדירוג"

        case .english:
            return "Ranking"

        case .arabic:
            return "الترتيب"
        }
    }

    private var rankingMessage:
        String {

        switch localization.language {

        case .hebrew:

            return
                "בדירוג תוכלו לראות איך הקבוצה שלכם מתקדמת מול קבוצות אחרות — עם דגש על רצף קבוצתי ושימוש ממוצע."

        case .english:

            return
                "The ranking shows how your group is doing compared with other groups, focusing on group streak and average usage."

        case .arabic:

            return
                "يعرض الترتيب تقدم مجموعتك مقارنة بالمجموعات الأخرى، مع التركيز على سلسلة النجاح ومتوسط الاستخدام."
        }
    }

    private var finishTitle:
        String {

        switch localization.language {

        case .hebrew:
            return "יוצאים לדרך"

        case .english:
            return "You're Ready"

        case .arabic:
            return "أنت جاهز"
        }
    }

    private var finishMessage:
        String {

        switch localization.language {

        case .hebrew:

            return
                "המטרה פשוטה: פחות זמן מסך, יותר זמן לדברים שבאמת חשובים לכם — ולעשות את זה יחד."

        case .english:

            return
                "The idea is simple: less screen time, more time for what actually matters — and doing it together."

        case .arabic:

            return
                "الفكرة بسيطة: وقت أقل أمام الشاشة ووقت أكثر لما يهمكم فعلًا — والقيام بذلك معًا."
        }
    }

    private var stepCounterText:
        String {

        switch localization.language {

        case .hebrew:
            return "שלב \(stepIndex + 1) מתוך \(steps.count)"

        case .english:
            return "Step \(stepIndex + 1) of \(steps.count)"

        case .arabic:
            return "الخطوة \(stepIndex + 1) من \(steps.count)"
        }
    }

    private var nextText:
        String {

        switch localization.language {

        case .hebrew:
            return "הבא"

        case .english:
            return "Next"

        case .arabic:
            return "التالي"
        }
    }

    private var backText:
        String {

        switch localization.language {

        case .hebrew:
            return "חזרה"

        case .english:
            return "Back"

        case .arabic:
            return "رجوع"
        }
    }

    private var skipText:
        String {

        switch localization.language {

        case .hebrew:
            return "סיום"

        case .english:
            return "Close"

        case .arabic:
            return "إغلاق"
        }
    }

    private var finishButtonText:
        String {

        switch localization.language {

        case .hebrew:
            return "הבנתי, מתחילים"

        case .english:
            return "Got It, Let's Start"

        case .arabic:
            return "فهمت، لنبدأ"
        }
    }
}

// MARK: - Tour Step

private struct TourStep {

    let destination:
        MemberOnboardingTour.TourDestination

    let icon: String

    let title: String

    let message: String
}
