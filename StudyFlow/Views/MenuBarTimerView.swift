import SwiftUI
import SwiftData

struct MenuBarTimerView: View {
    var viewModel: TimerViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var subjects: [Subject] = []
    @State private var isHoveringTag = false

    var body: some View {
        VStack(spacing: 12) {
            // Timer display with inline +/- buttons when idle
            VStack(spacing: 4) {
                Text(viewModel.phaseLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    if viewModel.status == .idle {
                        Button {
                            adjustDuration(by: -5)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.timeRemaining <= 60)
                        .opacity(viewModel.timeRemaining <= 60 ? 0.3 : 1)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    Text(viewModel.timeString)
                        .font(.system(size: 32, weight: .light, design: .monospaced))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())

                    if viewModel.status == .idle {
                        Button {
                            adjustDuration(by: 5)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hex: "#7C5CFC"))
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.timeRemaining >= 120 * 60)
                        .opacity(viewModel.timeRemaining >= 120 * 60 ? 0.3 : 1)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
            }
            .padding(.top, 8)

            // Tag picker (expands on hover)
            VStack(spacing: 4) {
                // Selected tag label
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: viewModel.selectedSubjectColorHex))
                        .frame(width: 8, height: 8)
                    Text(viewModel.selectedSubjectName.isEmpty ? "No Tag" : viewModel.selectedSubjectName)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isHoveringTag ? 180 : 0))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHoveringTag ? Color.primary.opacity(0.06) : .clear)
                )

                // Expanded tag list
                if isHoveringTag && !subjects.isEmpty {
                    VStack(spacing: 2) {
                        ForEach(subjects) { subject in
                            Button {
                                viewModel.selectedSubjectName = subject.name
                                viewModel.selectedSubjectColorHex = subject.colorHex
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: subject.colorHex))
                                        .frame(width: 6, height: 6)
                                    Text(subject.name)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if viewModel.selectedSubjectName == subject.name {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Color(hex: "#7C5CFC"))
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(viewModel.selectedSubjectName == subject.name
                                            ? Color(hex: subject.colorHex).opacity(0.12)
                                            : Color.clear)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(width: 180)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.04))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isHoveringTag)
            .onHover { hovering in
                isHoveringTag = hovering
                if hovering { fetchSubjects() }
            }

            // Controls
            HStack(spacing: 12) {
                Button {
                    viewModel.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.status == .idle)
                .opacity(viewModel.status == .idle ? 0.4 : 1)

                Button {
                    if viewModel.canStart {
                        setupSessionCallback()
                        viewModel.start()
                    } else {
                        viewModel.pause()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.canStart ? "play.fill" : "pause.fill")
                            .font(.system(size: 14))
                        Text(viewModel.canStart ? (viewModel.status == .paused ? "Resume" : "Start") : "Pause")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 100, height: 32)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#7C5CFC"), Color(hex: "#A855F7")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.skip()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }

            // Pomodoro count
            Text("\(viewModel.completedPomodoros) pomodoros")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
        }
        .padding(12)
        .onAppear {
            setupSessionCallback()
            fetchSubjects()
        }
    }

    private func fetchSubjects() {
        let descriptor = FetchDescriptor<Subject>(sortBy: [SortDescriptor(\.createdAt)])
        subjects = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func setupSessionCallback() {
        viewModel.onSessionCompleted = { name, color, duration, start, end in
            let session = StudySession(
                subjectName: name,
                subjectColorHex: color,
                duration: duration,
                startDate: start,
                endDate: end
            )
            modelContext.insert(session)
            try? modelContext.save()
        }
    }

    private func adjustDuration(by minutes: Int) {
        let currentMinutes = viewModel.timeRemaining / 60
        let snapped: Int
        if minutes > 0 {
            snapped = ((currentMinutes / 5) + 1) * 5
        } else {
            let mod = currentMinutes % 5
            snapped = mod == 0 ? currentMinutes - 5 : (currentMinutes / 5) * 5
        }
        let clamped = max(1, min(120, snapped)) * 60
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.timeRemaining = clamped
            viewModel.totalTime = clamped
        }
        switch viewModel.currentPhase {
        case .focus:
            viewModel.config.focusDuration = clamped
        case .shortBreak:
            viewModel.config.shortBreakDuration = clamped
        case .longBreak:
            viewModel.config.longBreakDuration = clamped
        }
        viewModel.config.save()
    }
}
