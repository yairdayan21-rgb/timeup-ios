import SwiftUI

// MARK: - Tour Steps

enum MemberOnboardingStep: Int, CaseIterable, Hashable {
    case personalTarget
    case alternatives
    case groupStatus
    case groupStreak
    case groupDetails
    case chat
    case ranking

    var position: Int {
        rawValue + 1
    }

    var isLast: Bool {
        self == .ranking
    }

    var scrollID: String {
        "member-onboarding-\(rawValue)"
    }

    var systemImage: String {
        switch self {
        case .personalTarget:
            return "target"
        case .alternatives:
            return "figure.walk"
        case .groupStatus:
            return "person.3.fill"
        case .groupStreak:
            return "flame.fill"
        case .groupDetails:
            return "chart.bar.fill"
        case .chat:
            return "bubble.left.and.bubble.right.fill"
        case .ranking:
            return "trophy.fill"
        }
    }
}

// MARK: - Coordinator

@MainActor
final class MemberOnboardingCoordinator: ObservableObject {

    static let shared = MemberOnboardingCoordinator()

    enum PresentationMode: Equatable {
        case firstTime
        case replay
    }

    @Published private(set) var isPresented = false
    @Published private(set) var presentationMode: PresentationMode = .firstTime
    @Published private(set) var currentStep: MemberOnboardingStep = .personalTarget
    @Published private(set) var isFinishing = false
    @Published private(set) var hasCompletionError = false

    private var presentingUserID: UUID?

    private init() {}

    func presentFirstTimeIfNeeded(
        user: SupabaseDataStore.TimeUpRemoteUser
    ) {
        guard !isPresented else {
            return
        }

        guard user.role
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() == "member"
        else {
            return
        }

        guard !user.onboardingCompleted else {
            return
        }

        presentingUserID = user.id
        begin(mode: .firstTime)
    }

    func presentReplay() {
        guard !isPresented else {
            return
        }

        guard let user = SupabaseDataStore.shared.currentUser,
              user.role == "member"
        else {
            return
        }

        presentingUserID = user.id
        begin(mode: .replay)
    }

    private func begin(mode: PresentationMode) {
        presentationMode = mode
        currentStep = .personalTarget
        hasCompletionError = false
        isFinishing = false
        isPresented = true
    }

    func next() {
        guard isPresented, !isFinishing,
              let nextStep = MemberOnboardingStep(
                rawValue: currentStep.rawValue + 1
              )
        else {
            return
        }

        hasCompletionError = false
        currentStep = nextStep
    }

    func previous() {
        guard isPresented, !isFinishing,
              let previousStep = MemberOnboardingStep(
                rawValue: currentStep.rawValue - 1
              )
        else {
            return
        }

        hasCompletionError = false
        currentStep = previousStep
    }

    func dismiss() {
        isPresented = false
        hasCompletionError = false
        presentingUserID = nil
    }

    func finish(
        dataStore: SupabaseDataStore
    ) async {
        guard isPresented, !isFinishing else {
            return
        }

        guard let userID = presentingUserID,
              dataStore.currentUser?.id == userID,
              dataStore.currentUser?.role == "member"
        else {
            dismiss()
            return
        }

        if presentationMode == .replay {
            dismiss()
            return
        }

        isFinishing = true
        hasCompletionError = false

        defer {
            isFinishing = false
        }

        do {
            try await dataStore.completeOnboarding()

            guard isPresented,
                  presentingUserID == userID
            else {
                return
            }

            guard dataStore.currentUser?.id == userID,
                  dataStore.currentUser?.onboardingCompleted == true
            else {
                hasCompletionError = true
                return
            }

            dismiss()

        } catch {
            guard isPresented,
                  presentingUserID == userID
            else {
                return
            }

            hasCompletionError = true
        }
    }

    func goalMethod(
        from dataStore: SupabaseDataStore
    ) -> String {
        dataStore.activeMemberGroup?.goalMethod ?? ""
    }
}

// MARK: - Spotlight Anchors

struct MemberOnboardingAnchorPreferenceKey: PreferenceKey {

    static var defaultValue:
        [MemberOnboardingStep: Anchor<CGRect>] {
        [:]
    }

    static func reduce(
        value: inout [MemberOnboardingStep: Anchor<CGRect>],
        nextValue: () -> [MemberOnboardingStep: Anchor<CGRect>]
    ) {
        value.merge(
            nextValue(),
            uniquingKeysWith: { _, newValue in newValue }
        )
    }
}

extension View {

    func memberOnboardingAnchor(
        _ step: MemberOnboardingStep
    ) -> some View {
        anchorPreference(
            key: MemberOnboardingAnchorPreferenceKey.self,
            value: .bounds
        ) { anchor in
            [step: anchor]
        }
    }
}

// MARK: - Spotlight Shape

private struct MemberOnboardingSpotlightShape: Shape {

    let highlightedFrame: CGRect?

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)

        if let highlightedFrame,
           !highlightedFrame.isEmpty {

            let visibleFrame = highlightedFrame
                .insetBy(dx: -6, dy: -6)
                .intersection(rect)

            if !visibleFrame.isNull,
               !visibleFrame.isEmpty {

                path.addRoundedRect(
                    in: visibleFrame,
                    cornerSize: CGSize(
                        width: 20,
                        height: 20
                    )
                )
            }
        }

        return path
    }
}

// MARK: - Guided Tour Overlay

struct MemberOnboardingTourOverlay: View {

    let highlightedFrame: CGRect?

    @ObservedObject private var coordinator =
        MemberOnboardingCoordinator.shared

    @ObservedObject private var dataStore =
        SupabaseDataStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    private var step: MemberOnboardingStep {
        coordinator.currentStep
    }

    private var explanationScrollID: String {
        "\(step.scrollID)-\(localization.language.rawValue)"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MemberOnboardingSpotlightShape(
                    highlightedFrame: highlightedFrame
                )
                .fill(
                    Color.black.opacity(0.52),
                    style: FillStyle(eoFill: true)
                )
                .accessibilityHidden(true)

                if let highlightedFrame,
                   !highlightedFrame.isEmpty {

                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                    .strokeBorder(
                        Color.white.opacity(0.95),
                        lineWidth: 2
                    )
                    .frame(
                        width: highlightedFrame.width + 12,
                        height: highlightedFrame.height + 12
                    )
                    .position(
                        x: highlightedFrame.midX,
                        y: highlightedFrame.midY
                    )
                    .accessibilityHidden(true)
                }

                VStack(spacing: 0) {
                    if placeCardAtBottom(in: geometry.size) {
                        Spacer(minLength: 16)
                    }

                    calloutCard
                        .frame(maxWidth: 440)

                    if !placeCardAtBottom(in: geometry.size) {
                        Spacer(minLength: 16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .contentShape(Rectangle())
            .onTapGesture {
                // Only the tour controls advance the tour.
            }
        }
        .environment(
            \.locale,
            localization.language.locale
        )
        .environment(
            \.layoutDirection,
            localization.language.layoutDirection
        )
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.2),
            value: step
        )
    }

    private func placeCardAtBottom(
        in size: CGSize
    ) -> Bool {
        guard let highlightedFrame else {
            return true
        }

        return highlightedFrame.midY < size.height / 2
    }

    private var calloutCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: step.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 42, height: 42)
                    .background(
                        Color.accentColor.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    Text(
                        "\(step.position) / \(MemberOnboardingStep.allCases.count)"
                    )
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            ScrollView {
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .id(explanationScrollID)
            .frame(maxHeight: 190)

            ProgressView(
                value: Double(step.position),
                total: Double(MemberOnboardingStep.allCases.count)
            )
            .accessibilityLabel(
                localized(
                    "התקדמות ההדרכה",
                    "Tutorial progress",
                    "تقدّم الدليل"
                )
            )

            if coordinator.hasCompletionError {
                Label(
                    localized(
                        "לא הצלחנו לשמור את סיום ההדרכה. בדוק את החיבור ונסה שוב.",
                        "We couldn't save tutorial completion. Check your connection and try again.",
                        "تعذّر حفظ إكمال الدليل. تحقّق من الاتصال وحاول مرة أخرى."
                    ),
                    systemImage: "exclamationmark.triangle"
                )
                .font(.footnote)
                .foregroundStyle(.red)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }

            HStack(spacing: 12) {
                if step != .personalTarget {
                    Button {
                        coordinator.previous()
                    } label: {
                        Text(
                            localized(
                                "הקודם",
                                "Back",
                                "السابق"
                            )
                        )
                        .frame(minHeight: 32)
                    }
                    .buttonStyle(.bordered)
                    .disabled(coordinator.isFinishing)
                }

                Spacer(minLength: 0)

                Button {
                    if step.isLast {
                        Task {
                            await coordinator.finish(
                                dataStore: dataStore
                            )
                        }
                    } else {
                        coordinator.next()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if coordinator.isFinishing {
                            ProgressView()
                                .tint(.white)
                        }

                        Text(primaryButtonTitle)
                            .fontWeight(.semibold)
                    }
                    .frame(minWidth: 92, minHeight: 32)
                }
                .buttonStyle(.borderedProminent)
                .disabled(coordinator.isFinishing)
            }
        }
        .padding(20)
        .background(
            .regularMaterial,
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .strokeBorder(
                Color.primary.opacity(0.08),
                lineWidth: 1
            )
        }
        .shadow(
            color: .black.opacity(0.18),
            radius: 20,
            y: 8
        )
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var primaryButtonTitle: String {
        if coordinator.isFinishing {
            return localized(
                "שומר...",
                "Saving...",
                "جارٍ الحفظ..."
            )
        }

        if coordinator.hasCompletionError {
            return localized(
                "נסה שוב",
                "Try Again",
                "حاول مجددًا"
            )
        }

        return step.isLast
            ? localized("סיום", "Finish", "إنهاء")
            : localized("הבא", "Next", "التالي")
    }

    // MARK: - Localized Titles

    private var title: String {
        switch step {
        case .personalTarget:
            return localized(
                "היעד האישי שלך",
                "Your Personal Target",
                "هدفك الشخصي"
            )

        case .alternatives:
            return localized(
                "זמן לדברים אחרים",
                "Make Time for Other Things",
                "وقت لأشياء أخرى"
            )

        case .groupStatus:
            return localized(
                "מצליחים ביחד",
                "Succeed Together",
                "ننجح معًا"
            )

        case .groupStreak:
            return localized(
                "הרצף הקבוצתי",
                "Your Group Streak",
                "سلسلة نجاح المجموعة"
            )

        case .groupDetails:
            return localized(
                "רואים את התמונה המלאה",
                "See the Full Picture",
                "شاهد الصورة الكاملة"
            )

        case .chat:
            return localized(
                "הקבוצה כאן בשבילך",
                "Your Group Is Here for You",
                "مجموعتك هنا لدعمك"
            )

        case .ranking:
            return localized(
                "ההתקדמות של הקבוצה",
                "Your Group's Progress",
                "تقدّم مجموعتك"
            )
        }
    }

    // MARK: - Localized Explanations

    private var explanation: String {
        switch step {
        case .personalTarget:
            return personalTargetExplanation

        case .alternatives:
            return localized(
                "כאן מופיעות חמש הצעות לפעילויות בלי מסך. סימנת פעילות שביצעת? היא מתחלפת מיד באחרת. אפשר לבצע כמה פעילויות שרוצים ביום, ופעילות שהשלמת היום לא תחזור היום. הפעילויות לא משנות את היעד או את הרצף.",
                "Here you'll find five ideas for screen-free activities. Mark an activity you've completed and another replaces it immediately. Complete as many as you like each day; completed activities won't return that day. Activities don't change your target or streak.",
                "ستجد هنا خمس أفكار لأنشطة دون شاشة. عند تحديد نشاط أكملته، يُستبدل فورًا بآخر. يمكنك إكمال أي عدد من الأنشطة يوميًا، ولن يعود النشاط المكتمل في اليوم نفسه. الأنشطة لا تغيّر هدفك أو سلسلة النجاح."
            )

        case .groupStatus:
            return localized(
                "הקבוצה עוזרת לך לעמוד ביעד — ואתה עוזר לקבוצה להצליח. יום מוצלח דורש שכל חברי הקבוצה יעמדו ביעד האישי שלהם. תוצאת היום נקבעת בשרת לאחר קבלת הנתונים של כולם; נתון חסר משאיר את היום בהמתנה.",
                "Your group helps you meet your target, and you help your group succeed. A successful day requires every member to meet their personal target. The server finalizes the result after everyone's data arrives; missing data keeps the day pending.",
                "تساعدك المجموعة على تحقيق هدفك، وأنت تساعد المجموعة على النجاح. يتطلّب اليوم الناجح أن يحقق جميع الأعضاء أهدافهم الشخصية. يحدّد الخادم النتيجة بعد وصول بيانات الجميع؛ وتبقى النتيجة قيد الانتظار إذا كانت هناك بيانات ناقصة."
            )

        case .groupStreak:
            return localized(
                "כשכולם עומדים ביעד, הרצף עולה ביום אחד. אם אפילו חבר אחד חורג מהיעד, הרצף מתאפס. יום הלמידה מודד את השימוש לצורך קביעת היעד הראשון ואינו נספר ברצף.",
                "When everyone meets their target, the streak increases by one day. If even one member exceeds their target, the streak resets. The learning day measures usage to establish the first target and doesn't count toward the streak.",
                "عندما يحقق الجميع أهدافهم، تزيد سلسلة النجاح يومًا واحدًا. إذا تجاوز عضو واحد هدفه، تبدأ السلسلة من الصفر. يقيس يوم التعلّم الاستخدام لتحديد الهدف الأول ولا يُحتسب ضمن السلسلة."
            )

        case .groupDetails:
            return localized(
                "בפירוט הקבוצתי מוצגים נתוני השימוש והיעדים של החברים להיום, כשנתוני היום זמינים. כך אפשר לראות מי עומד ביעד ואיפה הקבוצה יכולה לעזור. אם הנתונים עדיין לא הגיעו, מוצגת המתנה לנתוני היום.",
                "Group Details shows members' usage and targets for today when today's data is available. See who is meeting their target and where the group can help. If data hasn't arrived yet, the screen shows that today's data is pending.",
                "تعرض تفاصيل المجموعة استخدام الأعضاء وأهدافهم لهذا اليوم عندما تتوفّر بيانات اليوم. يمكنك معرفة من يحقق هدفه وأين يمكن للمجموعة تقديم المساعدة. إذا لم تصل البيانات بعد، تعرض الشاشة أنها بانتظار بيانات اليوم."
            )

        case .chat:
            return localized(
                "זה הצ׳אט של הקבוצה: מקום לעידוד, לשיתוף פעילות ולבקשת עזרה כשקשה להניח את הטלפון. התג ליד הצ׳אט מציין הודעות שעדיין לא קראת.",
                "This is your group chat: a place to encourage each other, share activities, and ask for help when putting the phone down feels difficult. The chat badge shows messages you haven't read yet.",
                "هذه دردشة مجموعتك: مكان للتشجيع، ومشاركة الأنشطة، وطلب المساعدة عندما يصعب ترك الهاتف. تشير شارة الدردشة إلى الرسائل التي لم تقرأها بعد."
            )

        case .ranking:
            return localized(
                "כאן אפשר לראות את דירוג הקבוצות ואת נתוני ההתקדמות שלהן. המטרה היומית נשארת משותפת: לעמוד ביעד האישי ולעזור לכל הקבוצה להצליח.",
                "Here you can see group rankings and their progress. Your daily goal remains shared: meet your personal target and help the whole group succeed.",
                "يمكنك هنا مشاهدة ترتيب المجموعات وبيانات تقدّمها. يبقى الهدف اليومي مشتركًا: تحقيق هدفك الشخصי ومساعدة المجموعة بأكملها على النجاح."
            )
        }
    }

    private var personalTargetExplanation: String {
        let introduction = localized(
            "כאן רואים את זמן השימוש ואת היעד האישי שלך להיום.",
            "Here you can see your usage and personal target for today.",
            "يمكنك هنا رؤية استخدامك وهدفك الشخصي لهذا اليوم."
        )

        let method = coordinator.goalMethod(from: dataStore)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let percent = dataStore.activeMemberGroup?.reductionPercent
        let reduction = percent.map { "\($0)%" }

        let methodExplanation: String

        switch method {
        case "previousday":
            let amount = reduction ?? localized(
                "האחוז שהמנהל קבע",
                "the percentage set by the admin",
                "النسبة التي حدّدها المسؤول"
            )

            methodExplanation = localized(
                "כשהקבוצה כולה מצליחה, היעד הבא שלך מחושב לפי השימוש האישי שלך באותו יום, פחות \(amount). אם הקבוצה לא מצליחה, היעד הקודם נשאר.",
                "When the whole group succeeds, your next target is based on your own usage that day, reduced by \(amount). If the group doesn't succeed, your previous target stays.",
                "عندما تنجح المجموعة بأكملها، يعتمد هدفك التالي على استخدامك الشخصي في ذلك اليوم، بعد تخفيضه بمقدار \(amount). إذا لم تنجح المجموعة، يبقى هدفك السابق."
            )

        case "adaptiveaverage":
            let amount = reduction ?? localized(
                "האחוז שהמנהל קבע",
                "the percentage set by the admin",
                "النسبة التي حدّدها المسؤول"
            )

            methodExplanation = localized(
                "כשהקבוצה כולה מצליחה, היעד הבא מבוסס על ממוצע השימוש בפועל של הקבוצה באותו יום, פחות \(amount), בעיגול כלפי מעלה לדקה שלמה. כולם מקבלים אותו יעד. אם הקבוצה לא מצליחה, היעד נשאר.",
                "When the whole group succeeds, the next target uses the group's actual average usage that day, reduced by \(amount) and rounded up to a whole minute. Everyone receives the same target. If the group doesn't succeed, the target stays.",
                "عندما تنجح المجموعة بأكملها، يعتمد الهدف التالي على متوسط استخدامها الفعلي في ذلك اليوم، بعد تخفيضه بمقدار \(amount) وتقريبه إلى الدقيقة الكاملة الأعلى. يحصل الجميع على الهدف نفسه. إذا لم تنجح المجموعة، يبقى الهدف."
            )

        case "manual":
            methodExplanation = localized(
                "המנהל הגדיר לך יעד אישי קבוע. הוא נשאר ללא שינוי עד שהמנהל מעדכן אותו.",
                "The admin has set a fixed personal target for you. It stays unchanged until the admin updates it.",
                "حدّد المسؤول لك هدفًا شخصيًا ثابتًا. يبقى دون تغيير حتى يحدّثه المسؤول."
            )

        default:
            methodExplanation = localized(
                "היעד נקבע לפי הגדרות הקבוצה. ההסבר המדויק יהיה זמין לאחר טעינת שיטת היעד.",
                "Your target follows your group's settings. The specific explanation becomes available once the target method loads.",
                "يُحدّد هدفك وفق إعدادات المجموعة. سيتوفّر الشرح المحدّد بعد تحميل طريقة تحديد الهدف."
            )
        }

        return "\(introduction)\n\n\(methodExplanation)"
    }

    private func localized(
        _ hebrew: String,
        _ english: String,
        _ arabic: String
    ) -> String {
        switch localization.language {
        case .hebrew:
            return hebrew
        case .english:
            return english
        case .arabic:
            return arabic
        }
    }
}