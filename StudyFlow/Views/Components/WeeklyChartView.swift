import SwiftUI
import Charts

struct WeeklyChartView: View {
    var statsVM: StatsViewModel
    
    @State private var hoveredDay: Date? = nil
    @State private var hoverPosition: CGPoint = .zero
    @State private var chartWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            if statsVM.dailyTotals.isEmpty || statsVM.dailyTotals.allSatisfy({ $0.duration == 0 }) {
                Text("No sessions recorded yet")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.paddingLg)
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
        return CGFloat(16 + 80 + 6 + breakdown.count * 19 + 20)
    }

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
}
