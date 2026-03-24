import SwiftUI
import SwiftData

@main
struct StudyFlowApp: App {
    @State private var timerVM = TimerViewModel()
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: StudySession.self, Subject.self, Project.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(timerVM: timerVM)
                .frame(minWidth: 520, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 520, height: 700)
        .modelContainer(modelContainer)

        MenuBarExtra {
            MenuBarTimerView(viewModel: timerVM)
                .modelContainer(modelContainer)
                .frame(width: 220)
        } label: {
            MenuBarLabel(viewModel: timerVM)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .modelContainer(modelContainer)
        }
    }
}

// MARK: - Menu Bar Label

struct MenuBarLabel: View {
    var viewModel: TimerViewModel
    @State private var displayText: String = "25:00"
    @State private var refreshTimer: Timer?

    var body: some View {
        Text("⏱ \(displayText)")
            .onAppear {
                displayText = viewModel.timeString
                // Poll every second to update the menu bar text
                refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    Task { @MainActor in
                        displayText = viewModel.timeString
                    }
                }
            }
            .onDisappear {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
    }
}
