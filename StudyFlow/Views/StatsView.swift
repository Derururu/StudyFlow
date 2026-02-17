import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \StudySession.startDate, order: .reverse) private var sessions: [StudySession]
    @State private var statsVM = StatsViewModel()

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
                    .foregroundStyle(Theme.accentGradient)
                    .cornerRadius(6)
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
            }
        }
        .padding(Theme.paddingMd)
        .glassCard()
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

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundStyle(Theme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.paddingLg)
    }
}
