import SwiftUI
import SwiftData

struct MenuBarTimerView: View {
    var viewModel: TimerViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var subjects: [Subject] = []
    @State private var projects: [Project] = []

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
                            viewModel.adjustDuration(by: -5)
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
                            viewModel.adjustDuration(by: 5)
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

            // Tag picker (native dropdown)
            Menu {
                ForEach(subjects) { subject in
                    Button {
                        viewModel.selectedSubjectName = subject.name
                        viewModel.selectedSubjectColorHex = subject.colorHex
                    } label: {
                        HStack {
                            Image(systemName: viewModel.selectedSubjectName == subject.name ? "checkmark.circle.fill" : "circle.fill")
                            Text(subject.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: viewModel.selectedSubjectColorHex))
                        .frame(width: 8, height: 8)
                    Text(viewModel.selectedSubjectName.isEmpty ? "No Tag" : viewModel.selectedSubjectName)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            // Project picker (native dropdown)
            Menu {
                Button {
                    viewModel.selectedProjectName = ""
                    viewModel.selectedProjectColorHex = ""
                } label: {
                    HStack {
                        Image(systemName: viewModel.selectedProjectName.isEmpty ? "checkmark.circle.fill" : "circle")
                        Text("No Project")
                    }
                }

                ForEach(projects) { project in
                    Button {
                        viewModel.selectedProjectName = project.name
                        viewModel.selectedProjectColorHex = project.colorHex
                    } label: {
                        HStack {
                            Image(systemName: viewModel.selectedProjectName == project.name ? "checkmark.circle.fill" : "circle.fill")
                            Text(project.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(viewModel.selectedProjectName.isEmpty ? .secondary : Color(hex: viewModel.selectedProjectColorHex))
                    Text(viewModel.selectedProjectName.isEmpty ? "No Project" : viewModel.selectedProjectName)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

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
            viewModel.setupSessionCallback(modelContext: modelContext)
            fetchSubjects()
            fetchProjects()
        }
    }

    private func fetchSubjects() {
        let descriptor = FetchDescriptor<Subject>(sortBy: [SortDescriptor(\.createdAt)])
        subjects = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchProjects() {
        let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.createdAt)])
        projects = (try? modelContext.fetch(descriptor)) ?? []
    }

}
