import SwiftUI
import SwiftData

struct MenuBarTimerView: View {
    var viewModel: TimerViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 12) {
            // Timer display
            VStack(spacing: 4) {
                Text(viewModel.phaseLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(viewModel.timeString)
                    .font(.system(size: 32, weight: .light, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            .padding(.top, 8)

            // Tag
            if !viewModel.selectedSubjectName.isEmpty {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: viewModel.selectedSubjectColorHex))
                        .frame(width: 8, height: 8)
                    Text(viewModel.selectedSubjectName)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
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
        }
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
}
