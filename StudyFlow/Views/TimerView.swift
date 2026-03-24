import SwiftUI
import SwiftData

struct TimerView: View {
    @Bindable var viewModel: TimerViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.paddingLg) {
                // Pomodoro counter
                pomodoroCounter

                // Timer ring
                CircularProgressRing(
                    progress: viewModel.progress,
                    phase: viewModel.currentPhase,
                    timeString: viewModel.timeString,
                    phaseLabel: viewModel.phaseLabel
                )
                .padding(.vertical, Theme.paddingMd)

                // Duration adjuster (visible when idle)
                if viewModel.status == .idle {
                    durationAdjuster
                }

                // Phase selector
                phaseSelector

                // Subject picker
                SubjectPickerView(
                    selectedSubjectName: $viewModel.selectedSubjectName,
                    selectedSubjectColorHex: $viewModel.selectedSubjectColorHex
                )

                // Project picker
                ProjectPickerView(
                    selectedProjectName: $viewModel.selectedProjectName,
                    selectedProjectColorHex: $viewModel.selectedProjectColorHex
                )

                // Session Notes
                SessionNotesPanel(viewModel: viewModel)

                // Controls
                controlButtons
            }
            .padding(Theme.paddingLg)
        }
        .onAppear {
            viewModel.setupSessionCallback(modelContext: modelContext)
        }
    }

    // MARK: - Pomodoro Counter

    private var pomodoroCounter: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.config.longBreakInterval, id: \.self) { i in
                Circle()
                    .fill(i < (viewModel.completedPomodoros % viewModel.config.longBreakInterval)
                        ? Theme.accent : Theme.surfaceLight)
                    .frame(width: 10, height: 10)
                    .shadow(color: i < (viewModel.completedPomodoros % viewModel.config.longBreakInterval)
                        ? Theme.accent.opacity(0.5) : .clear, radius: 4)
            }

            Text("\(viewModel.completedPomodoros) pomodoros")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .padding(.leading, 4)
        }
    }

    // MARK: - Duration Adjuster

    private var durationAdjuster: some View {
        HStack(spacing: 16) {
            // Minus 5 min
            Button {
                viewModel.adjustDuration(by: -5)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.textSecondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.timeRemaining <= 60)
            .opacity(viewModel.timeRemaining <= 60 ? 0.3 : 1)

            VStack(spacing: 2) {
                Text("\(viewModel.timeRemaining / 60)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())

                Text("minutes")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
            }
            .frame(width: 70)

            // Plus 5 min
            Button {
                viewModel.adjustDuration(by: 5)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accent)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.timeRemaining >= 120 * 60)
            .opacity(viewModel.timeRemaining >= 120 * 60 ? 0.3 : 1)
        }
        .padding(.vertical, 4)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Phase Selector

    private var phaseSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimerPhase.allCases, id: \.self) { phase in
                Button {
                    viewModel.setPhase(phase)
                } label: {
                    Text(phase.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(
                            viewModel.currentPhase == phase
                                ? Theme.textPrimary
                                : Theme.textMuted
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.currentPhase == phase
                                ? Theme.accent.opacity(0.2)
                                : Theme.surfaceLight.opacity(0.3)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }



    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: 16) {
            // Reset
            Button {
                viewModel.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Theme.surfaceLight.opacity(0.4))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.status == .idle)
            .opacity(viewModel.status == .idle ? 0.4 : 1)

            // Start / Pause
            Button {
                if viewModel.canStart {
                    viewModel.start()
                } else {
                    viewModel.pause()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.canStart ? "play.fill" : "pause.fill")
                        .font(.system(size: 18))

                    Text(viewModel.canStart ? "Start" : "Pause")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(width: 140, height: 50)
                .background(
                    viewModel.currentPhase == .focus
                        ? Theme.focusGradient
                        : Theme.breakGradient
                )
                .clipShape(Capsule())
                .shadow(
                    color: (viewModel.currentPhase == .focus ? Theme.accent : Theme.success).opacity(0.4),
                    radius: 12, y: 4
                )
            }
            .buttonStyle(.plain)

            // Skip
            Button {
                viewModel.skip()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Theme.surfaceLight.opacity(0.4))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}
