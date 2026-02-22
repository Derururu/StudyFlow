import SwiftUI
import SwiftData

struct TimerView: View {
    @Bindable var viewModel: TimerViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.createdAt) private var subjects: [Subject]

    @State private var showingSubjectEditor = false
    @State private var newSubjectName = ""
    @State private var selectedTagColor = "#7C5CFC"

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
                subjectPicker

                // Controls
                controlButtons
            }
            .padding(Theme.paddingLg)
        }
        .onAppear {
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
                adjustDuration(by: -5)
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
                adjustDuration(by: 5)
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

    private func adjustDuration(by minutes: Int) {
        let currentMinutes = viewModel.timeRemaining / 60
        let snapped: Int
        if minutes > 0 {
            // Round up to next multiple of 5
            snapped = ((currentMinutes / 5) + 1) * 5
        } else {
            // Round down to previous multiple of 5, or subtract 5 if already on a multiple
            let mod = currentMinutes % 5
            snapped = mod == 0 ? currentMinutes - 5 : (currentMinutes / 5) * 5
        }
        let clamped = max(1, min(120, snapped)) * 60
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.timeRemaining = clamped
            viewModel.totalTime = clamped
        }
        // Also update config for the current phase so it persists
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

    // MARK: - Tag Picker

    private var subjectPicker: some View {
        VStack(spacing: 8) {
            Text("TAGS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textMuted)
                .tracking(1.5)

            if subjects.isEmpty {
                // Empty state — prompt to create first tag
                Button {
                    showingSubjectEditor = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Create your first tag")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.accent.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(subjects) { subject in
                            Button {
                                viewModel.selectedSubjectName = subject.name
                                viewModel.selectedSubjectColorHex = subject.colorHex
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: subject.colorHex))
                                        .frame(width: 8, height: 8)

                                    Text(subject.name)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .foregroundStyle(
                                    viewModel.selectedSubjectName == subject.name
                                        ? Theme.textPrimary
                                        : Theme.textSecondary
                                )
                                .background(
                                    viewModel.selectedSubjectName == subject.name
                                        ? Color(hex: subject.colorHex).opacity(0.2)
                                        : Theme.surfaceLight.opacity(0.3)
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    viewModel.selectedSubjectName == subject.name
                                        ? Capsule().stroke(Color(hex: subject.colorHex).opacity(0.5), lineWidth: 1)
                                        : nil
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteTag(subject)
                                } label: {
                                    Label("Delete Tag", systemImage: "trash")
                                }
                            }
                        }

                        // Add tag button
                        Button {
                            showingSubjectEditor = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                                .frame(width: 28, height: 28)
                                .background(Theme.surfaceLight.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSubjectEditor) {
            addTagSheet
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

    // MARK: - Add Tag Sheet

    private var addTagSheet: some View {
        VStack(spacing: 16) {
            Text("New Tag")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            TextField("Tag name (e.g. DSA, Physics, Reading)", text: $newSubjectName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 260)

            // Color picker
            VStack(spacing: 6) {
                Text("COLOR")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textMuted)
                    .tracking(1)

                HStack(spacing: 8) {
                    ForEach(Subject.tagColors, id: \.self) { colorHex in
                        Button {
                            selectedTagColor = colorHex
                        } label: {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    selectedTagColor == colorHex
                                        ? Circle().stroke(.white, lineWidth: 2)
                                        : nil
                                )
                                .shadow(color: selectedTagColor == colorHex
                                    ? Color(hex: colorHex).opacity(0.6) : .clear,
                                    radius: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    newSubjectName = ""
                    showingSubjectEditor = false
                }

                Button("Add Tag") {
                    guard !newSubjectName.isEmpty else { return }
                    let subject = Subject(name: newSubjectName, colorHex: selectedTagColor)
                    modelContext.insert(subject)
                    try? modelContext.save()
                    // Auto-select the new tag
                    viewModel.selectedSubjectName = newSubjectName
                    viewModel.selectedSubjectColorHex = selectedTagColor
                    newSubjectName = ""
                    showingSubjectEditor = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newSubjectName.isEmpty)
            }
        }
        .padding(Theme.paddingLg)
        .frame(width: 340, height: 200)
        .background(Theme.background)
    }

    // MARK: - Helpers

    private func deleteTag(_ subject: Subject) {
        if viewModel.selectedSubjectName == subject.name {
            viewModel.selectedSubjectName = subjects.first(where: { $0.id != subject.id })?.name ?? ""
            viewModel.selectedSubjectColorHex = subjects.first(where: { $0.id != subject.id })?.colorHex ?? "#868E96"
        }
        modelContext.delete(subject)
        try? modelContext.save()
    }
}

