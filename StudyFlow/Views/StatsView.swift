import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \StudySession.startDate, order: .reverse) private var sessions: [StudySession]
    @Query(sort: \Project.createdAt) private var projects: [Project]
    @State private var statsVM = StatsViewModel()
    @State private var hoveredDay: Date? = nil
    @State private var hoverPosition: CGPoint = .zero

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.paddingMd) {
                // Header
                Text("Dashboard")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)

                // Stat cards
                statCards

                // Weekly chart
                weeklyChart

                // Subject breakdown
                subjectBreakdown

                // Project filter + pie chart
                projectBreakdownSection
            }
            .padding(Theme.paddingLg)
        }
        .background(Theme.background)
        .onAppear { statsVM.refresh(sessions: sessions) }
        .onChange(of: sessions.count) { _, _ in statsVM.refresh(sessions: sessions) }
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: "Today",
                value: statsVM.formatDuration(statsVM.todayTotal),
                icon: "sun.max.fill",
                color: Theme.warning
            )

            StatCard(
                title: "This Week",
                value: statsVM.formatDuration(statsVM.weekTotal),
                icon: "calendar",
                color: Theme.accent
            )

            StatCard(
                title: "Streak",
                value: "\(statsVM.currentStreak) day\(statsVM.currentStreak == 1 ? "" : "s")",
                icon: "flame.fill",
                color: Theme.danger
            )

            StatCard(
                title: "Sessions",
                value: "\(statsVM.todaySessions) today",
                icon: "checkmark.circle.fill",
                color: Theme.success
            )
        }
    }

    // MARK: - Weekly Chart

    @State private var chartWidth: CGFloat = 0

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            if statsVM.dailyTotals.isEmpty || statsVM.dailyTotals.allSatisfy({ $0.duration == 0 }) {
                emptyState("No sessions recorded yet")
            } else {
                Chart(Array(statsVM.dailyTotals.enumerated()), id: \.offset) { _, item in
                    BarMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Minutes", item.duration / 60)
                    )
                    .foregroundStyle(
                        hoveredDay != nil && Calendar.current.isDate(item.date, inSameDayAs: hoveredDay!)
                            ? AnyShapeStyle(Theme.accent)
                            : AnyShapeStyle(Theme.accentGradient)
                    )
                    .cornerRadius(6)
                    .opacity(hoveredDay == nil || Calendar.current.isDate(item.date, inSameDayAs: hoveredDay!) ? 1.0 : 0.4)
                }
                .chartYAxisLabel("minutes")
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(Theme.surfaceLight.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .frame(height: 160)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onAppear {
                                chartWidth = geo.size.width
                            }
                            .onChange(of: geo.size.width) { _, newWidth in
                                chartWidth = newWidth
                            }
                            .onContinuousHover { phase in
                                DispatchQueue.main.async {
                                    switch phase {
                                    case .active(let location):
                                        if let date: Date = proxy.value(atX: location.x) {
                                            let calendar = Calendar.current
                                            let day = calendar.startOfDay(for: date)
                                            if statsVM.dailyTotals.contains(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
                                                hoveredDay = day
                                                let centerX = proxy.position(forX: day) ?? location.x
                                                hoverPosition = CGPoint(x: centerX, y: 0)
                                            }
                                        }
                                    case .ended:
                                        hoveredDay = nil
                                    }
                                }
                            }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if let day = hoveredDay,
                       let breakdown = statsVM.dailyTagBreakdowns[day],
                       !breakdown.isEmpty {
                        let tooltipWidth: CGFloat = 150
                        let halfTip = tooltipWidth / 2
                        // Clamp so tooltip doesn't overflow left/right
                        let clampedX = min(max(hoverPosition.x - halfTip, 0), max(chartWidth - tooltipWidth, 0))

                        hoverPieChart(breakdown: breakdown, day: day)
                            .fixedSize()
                            .offset(x: clampedX)
                            .offset(y: -(hoverPieChartHeight(breakdown: breakdown) + 8))
                            .allowsHitTesting(false)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.15), value: hoveredDay)
                    }
                }
            }
        }
        .padding(Theme.paddingMd)
        .glassCard()
    }

    private func hoverPieChartHeight(breakdown: [(name: String, colorHex: String, duration: Int)]) -> CGFloat {
        // Approximate: date label ~16 + pie 80 + spacing + legend rows ~16 each + padding
        return CGFloat(16 + 80 + 6 + breakdown.count * 19 + 20)
    }

    // MARK: - Hover Pie Chart Tooltip

    private func hoverPieChart(breakdown: [(name: String, colorHex: String, duration: Int)], day: Date) -> some View {
        VStack(spacing: 6) {
            Text(day, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            Chart(Array(breakdown.enumerated()), id: \.offset) { _, item in
                SectorMark(
                    angle: .value("Duration", item.duration),
                    innerRadius: .ratio(0.45),
                    angularInset: 1.5
                )
                .foregroundStyle(Color(hex: item.colorHex))
                .cornerRadius(3)
            }
            .frame(width: 80, height: 80)

            // Compact legend
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(breakdown.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: item.colorHex))
                            .frame(width: 6, height: 6)

                        Text(item.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(statsVM.formatDuration(item.duration))
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .padding(10)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.surface.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.surfaceLight.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        )
    }

    // MARK: - Subject Breakdown

    private var subjectBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today by Subject")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            if statsVM.subjectBreakdown.isEmpty {
                emptyState("Start a session to see breakdown")
            } else {
                ForEach(Array(statsVM.subjectBreakdown.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: item.colorHex))
                            .frame(width: 10, height: 10)

                        Text(item.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        Text(statsVM.formatDuration(item.duration))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)

                        // Proportion bar
                        GeometryReader { geo in
                            let maxDuration = statsVM.subjectBreakdown.first?.duration ?? 1
                            let proportion = CGFloat(item.duration) / CGFloat(maxDuration)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: item.colorHex).opacity(0.4))
                                .frame(width: geo.size.width * proportion)
                        }
                        .frame(width: 80, height: 6)
                    }
                }
            }
        }
        .padding(Theme.paddingMd)
        .glassCard()
    }

    // MARK: - Project Breakdown Section

    private var projectBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Project Breakdown")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                // Project filter picker
                Menu {
                    Button {
                        statsVM.selectedProjectFilter = ""
                        statsVM.refresh(sessions: sessions)
                    } label: {
                        HStack {
                            if statsVM.selectedProjectFilter.isEmpty {
                                Image(systemName: "checkmark")
                            }
                            Text("All Projects")
                        }
                    }

                    ForEach(projects) { project in
                        Button {
                            statsVM.selectedProjectFilter = project.name
                            statsVM.refresh(sessions: sessions)
                        } label: {
                            HStack {
                                if statsVM.selectedProjectFilter == project.name {
                                    Image(systemName: "checkmark")
                                }
                                Text(project.name)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                        Text(statsVM.selectedProjectFilter.isEmpty ? "Select Project" : statsVM.selectedProjectFilter)
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(statsVM.selectedProjectFilter.isEmpty ? Theme.textMuted : Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.surfaceLight.opacity(0.4))
                    .clipShape(Capsule())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            if statsVM.selectedProjectFilter.isEmpty {
                emptyState("Select a project to see tag distribution")
            } else if statsVM.projectTagBreakdown.isEmpty {
                emptyState("No sessions for this project yet")
            } else {
                // Pie chart
                Chart(Array(statsVM.projectTagBreakdown.enumerated()), id: \.offset) { _, item in
                    SectorMark(
                        angle: .value("Duration", item.duration),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(hex: item.colorHex))
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .padding(.vertical, 4)

                // Legend
                ForEach(Array(statsVM.projectTagBreakdown.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: item.colorHex))
                            .frame(width: 8, height: 8)

                        Text(item.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        let totalDuration = statsVM.projectTagBreakdown.reduce(0) { $0 + $1.duration }
                        let percentage = totalDuration > 0 ? Int(Double(item.duration) / Double(totalDuration) * 100) : 0
                        Text("\(percentage)%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textMuted)

                        Text(statsVM.formatDuration(item.duration))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .padding(Theme.paddingMd)
        .glassCard()
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundStyle(Theme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.paddingLg)
    }
}

