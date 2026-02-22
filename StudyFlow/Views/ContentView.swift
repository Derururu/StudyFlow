import SwiftUI

enum AppTab: String, CaseIterable {
    case timer = "Timer"
    case stats = "Stats"
    case history = "History"

    var icon: String {
        switch self {
        case .timer: return "timer"
        case .stats: return "chart.bar.fill"
        case .history: return "clock.arrow.circlepath"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .timer
    @Bindable var timerVM: TimerViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Custom tab bar
                tabBar

                // Tab content
                Group {
                    switch selectedTab {
                    case .timer:
                        TimerView(viewModel: timerVM)
                    case .stats:
                        StatsView()
                    case .history:
                        HistoryView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            ToastView(isPresented: $timerVM.showWalkReminder)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: timerVM.showWalkReminder)
        }
        .background(Theme.background)
        .onAppear {
            timerVM.requestNotificationPermission()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))

                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? Theme.accent : Theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                    .background(
                        selectedTab == tab
                            ? Theme.accent.opacity(0.1)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.paddingMd)
        .padding(.top, Theme.paddingSm)
        .padding(.bottom, 4)
        .background(Theme.surface.opacity(0.8))
    }
}
